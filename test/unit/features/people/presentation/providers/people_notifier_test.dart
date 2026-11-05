import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockDmRepository extends Mock implements DmRepository {}

class _FakePeopleRepository implements PeopleRepository {
  final requests = <(int, String)>[];
  bool failPage2 = false;

  @override
  Future<Result<MembersPage>> fetchMembers({
    required String orgId,
    int page = 1,
    String search = '',
  }) async {
    requests.add((page, search));
    if (page == 2 && failPage2) {
      return const Failure(ApiFailure(message: 'offline'));
    }
    return Success(
      MembersPage(
        members: page == 1
            ? const [
                OrgMember(id: 'u-1', name: 'Ada'),
                OrgMember(id: 'u-2', name: 'Grace'),
              ]
            // u-2 again: pages can overlap when someone joins meanwhile.
            : const [
                OrgMember(id: 'u-2', name: 'Grace'),
                OrgMember(id: 'u-3', name: 'Linus'),
              ],
        currentPage: page,
        totalPages: 2,
        totalItems: 3,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers for workspace-switch race-condition tests
// ---------------------------------------------------------------------------

class _Org extends Notifier<String> {
  @override
  String build() => 'org-1';

  void select(String orgId) => state = orgId;
}

final _orgProvider = NotifierProvider<_Org, String>(_Org.new);

/// Repository whose fetches can be held in a [Completer] so that tests can
/// control exactly when a network response arrives.
class _HoldablePeopleRepository implements PeopleRepository {
  final _held = <String, Completer<Result<MembersPage>>>{};

  void hold(String orgId, int page) =>
      _held['$orgId/$page'] = Completer<Result<MembersPage>>();

  void complete(String orgId, int page, Result<MembersPage> result) =>
      _held['$orgId/$page']!.complete(result);

  MembersPage pageFor(String orgId, int page) => MembersPage(
    members: [OrgMember(id: '$orgId-p$page-0', name: 'User')],
    currentPage: page,
    totalPages: 2,
    totalItems: 2,
  );

  @override
  Future<Result<MembersPage>> fetchMembers({
    required String orgId,
    int page = 1,
    String search = '',
  }) {
    final completer = _held['$orgId/$page'];
    if (completer != null) return completer.future;
    return Future.value(Success(pageFor(orgId, page)));
  }
}

// ---------------------------------------------------------------------------

void main() {
  late _FakePeopleRepository people;
  late MockDmRepository dms;
  late ProviderContainer container;

  setUp(() {
    people = _FakePeopleRepository();
    dms = MockDmRepository();
    container = ProviderContainer(
      overrides: [
        currentOrgIdProvider.overrideWithValue('org-1'),
        peopleRepositoryProvider.overrideWithValue(people),
        dmRepositoryProvider.overrideWithValue(dms),
      ],
    );
    addTearDown(container.dispose);
  });

  group('PeopleListNotifier', () {
    test('loads the first page for its search', () async {
      final sub = container.listen(peopleListProvider('ada'), (_, _) {});
      addTearDown(sub.close);

      final list = await container.read(peopleListProvider('ada').future);

      expect(people.requests, [(1, 'ada')]);
      expect(list.members.map((m) => m.id), ['u-1', 'u-2']);
      expect(list.hasMore, isTrue);
      expect(list.total, 3);
    });

    test('load more adds the next page without duplicates', () async {
      final sub = container.listen(peopleListProvider(''), (_, _) {});
      addTearDown(sub.close);
      await container.read(peopleListProvider('').future);

      await container.read(peopleListProvider('').notifier).loadMore();

      final list = container.read(peopleListProvider('')).value!;
      expect(list.members.map((m) => m.id), ['u-1', 'u-2', 'u-3']);
      expect(list.hasMore, isFalse);

      // Nothing more to load.
      await container.read(peopleListProvider('').notifier).loadMore();
      expect(people.requests, [(1, ''), (2, '')]);
    });

    test('a failed load more keeps the members and can retry', () async {
      people.failPage2 = true;
      final sub = container.listen(peopleListProvider(''), (_, _) {});
      addTearDown(sub.close);
      await container.read(peopleListProvider('').future);

      await container.read(peopleListProvider('').notifier).loadMore();

      final list = container.read(peopleListProvider('')).value!;
      expect(list.members, hasLength(2));
      expect(list.loadMoreFailed, isTrue);
      expect(list.hasMore, isTrue);
    });
  });

  group('PeopleListNotifier workspace switch', () {
    late _HoldablePeopleRepository holdable;

    setUp(() {
      holdable = _HoldablePeopleRepository();
      container = ProviderContainer(
        overrides: [
          currentOrgIdProvider.overrideWith((ref) => ref.watch(_orgProvider)),
          peopleRepositoryProvider.overrideWithValue(holdable),
          dmRepositoryProvider.overrideWithValue(dms),
        ],
      );
      addTearDown(container.dispose);
    });

    test('loadMore completing after workspace switch does not overwrite new '
        'workspace members', () async {
      // Load page 1 for org-1.
      container.read(_orgProvider.notifier).select('org-1');
      final sub = container.listen(peopleListProvider(''), (_, _) {});
      addTearDown(sub.close);
      await container.read(peopleListProvider('').future);

      // Hold the page-2 fetch before it resolves.
      holdable.hold('org-1', 2);
      final loadMoreFuture = container
          .read(peopleListProvider('').notifier)
          .loadMore();

      // Switch workspace while the fetch is in flight.
      container.read(_orgProvider.notifier).select('org-2');

      // Let the stale fetch complete.
      holdable.complete('org-1', 2, Success(holdable.pageFor('org-1', 2)));
      await loadMoreFuture;

      // The stale page must NOT have been appended to org-2's list.
      final state = container.read(peopleListProvider(''));
      if (state.hasValue) {
        final ids = state.value!.members.map((m) => m.id).toList();
        expect(ids, isNot(contains('org-1-p2-0')));
      }
    });

    test('loadMore failing after workspace switch does not overwrite new '
        'workspace members', () async {
      // Load page 1 for org-1.
      container.read(_orgProvider.notifier).select('org-1');
      final sub = container.listen(peopleListProvider(''), (_, _) {});
      addTearDown(sub.close);
      await container.read(peopleListProvider('').future);

      // Hold the page-2 fetch, then switch workspace.
      holdable.hold('org-1', 2);
      final loadMoreFuture = container
          .read(peopleListProvider('').notifier)
          .loadMore();
      container.read(_orgProvider.notifier).select('org-2');

      // The stale fetch fails.
      holdable.complete(
        'org-1',
        2,
        const Failure<MembersPage>(ApiFailure(message: 'timeout')),
      );
      await loadMoreFuture;

      // org-2's list must not have been corrupted by the stale error path.
      final state = container.read(peopleListProvider(''));
      if (state.hasValue) {
        expect(state.value!.loadMoreFailed, isFalse);
      }
    });
  });

  group('PeopleActionsNotifier.openChat', () {
    const ada = OrgMember(id: 'u-1', name: 'Ada', email: 'ada@zedu.test');

    test('opens the DM and shows it in the DMs tab', () async {
      when(
        () => dms.openConversation(orgId: 'org-1', participantId: 'u-1'),
      ).thenAnswer((_) async => (channelId: 'c-1', participantId: 'u-1'));

      final opened = await container
          .read(peopleActionsProvider.notifier)
          .openChat(ada);

      expect(opened, isTrue);
      final dm = container.read(selectedDmProvider)!;
      expect(dm.channelId, 'c-1');
      expect(dm.displayName, 'Ada');
      expect(dm.participantEmail, 'ada@zedu.test');
      expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
      expect(container.read(peopleActionsProvider), isNull);
    });

    test('reports a failure and stays on People', () async {
      when(
        () => dms.openConversation(orgId: 'org-1', participantId: 'u-1'),
      ).thenThrow(const ApiFailure(message: 'offline'));
      container
          .read(homeSidebarProvider.notifier)
          .setType(HomeSidebarType.people);

      final opened = await container
          .read(peopleActionsProvider.notifier)
          .openChat(ada);

      expect(opened, isFalse);
      expect(container.read(selectedDmProvider), isNull);
      expect(container.read(homeSidebarProvider), HomeSidebarType.people);
      expect(container.read(peopleActionsProvider), isNull);
    });
  });
}
