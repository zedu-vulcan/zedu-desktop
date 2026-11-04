import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockChatWebsocketService extends Mock implements ChatWebsocketService {}

class MockApiBaseService extends Mock implements ApiBaseService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      phone: '',
      username: 'tester',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org-1',
      currentOrganisationSlug: 'test-org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

void main() {
  const members = [
    TeamMember(
      id: 'm1',
      email: 'one@example.com',
      role: 'member',
      dateJoined: '2026-01-01',
      status: TeamMemberStatus.active,
    ),
    TeamMember(
      id: 'm2',
      email: 'two@example.com',
      role: 'member',
      dateJoined: '2026-01-01',
      status: TeamMemberStatus.active,
    ),
  ];

  group('Group DM offline delivery and websocket lifecycle', () {
    late MockChatWebsocketService mockWs;
    late MockApiBaseService mockApi;
    late MockSecureStorageService mockStorage;
    late StreamController<ChatWebsocketMessage> wsController;
    late ProviderContainer container;
    late Map<String, String> stored;

    setUp(() {
      stored = {};
      mockWs = MockChatWebsocketService();
      mockApi = MockApiBaseService();
      mockStorage = MockSecureStorageService();
      wsController = StreamController<ChatWebsocketMessage>.broadcast();

      when(() => mockWs.messageStream).thenAnswer((_) => wsController.stream);

      when(() => mockWs.connect(any())).thenReturn(null);

      when(() => mockStorage.readData(any())).thenAnswer(
        (invocation) async =>
            stored[invocation.positionalArguments[0] as String],
      );

      when(() => mockStorage.writeData(any(), any())).thenAnswer((
        invocation,
      ) async {
        stored[invocation.positionalArguments[0] as String] =
            invocation.positionalArguments[1] as String;
      });

      when(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/organisations/org-1/group-dms',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {
            'data': {'channel_id': 'group-1'},
          },
          statusCode: 201,
        ),
      );

      locator.registerSingleton<ApiBaseService>(mockApi);
      locator.registerSingleton<SecureStorageService>(mockStorage);

      container = ProviderContainer(
        overrides: [
          chatWebsocketProvider.overrideWithValue(mockWs),
          authNotifierProvider.overrideWith(FakeAuthNotifier.new),
          reachabilityCheckerProvider.overrideWith(
            (ref) =>
                () async => true,
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await wsController.close();
      await locator.reset();
    });

    Future<String> createGroup() async {
      final result = await container
          .read(groupDmProvider.notifier)
          .createGroupDm(members);

      expect(result, isA<Success<GroupDM>>());
      return (result as Success<GroupDM>).value.id;
    }

    test('creates group and receives incoming websocket messages', () async {
      expect(container.read(groupDmProvider), isEmpty);
      final groupId = await createGroup();

      wsController.add(
        ChatWebsocketMessage(
          groupDmId: groupId,
          text: 'Hello from websocket',
          authorName: 'Test Author',
          timestamp: DateTime.now(),
        ),
      );

      await pumpEventQueue();

      final group = container.read(groupDmProvider).single;

      expect(group.messages, contains('Hello from websocket'));
      expect(group.unreadCount, 1);
    });

    test(
      'websocket listener stops receiving messages after disposal',
      () async {
        container.read(groupDmProvider);
        container.invalidate(groupDmProvider);

        expect(
          () => wsController.add(
            ChatWebsocketMessage(
              groupDmId: 'group-1',
              text: 'After invalidation',
              authorName: 'Test Author',
              timestamp: DateTime.now(),
            ),
          ),
          returnsNormally,
        );

        await pumpEventQueue();
      },
    );

    test(
      'rebuilding the provider does not duplicate websocket messages',
      () async {
        await createGroup();

        container.invalidate(groupDmProvider);

        expect(container.read(groupDmProvider), isEmpty);

        final groupId = await createGroup();

        wsController.add(
          ChatWebsocketMessage(
            groupDmId: groupId,
            text: 'Exactly once',
            authorName: 'Test Author',
            timestamp: DateTime.now(),
          ),
        );

        await pumpEventQueue();

        final group = container.read(groupDmProvider).single;

        expect(group.messages.where((m) => m == 'Exactly once'), hasLength(1));
        expect(group.unreadCount, 1);
      },
    );

    test('offline message persists and is delivered after reconnect', () async {
      final groupId = await createGroup();
      await pumpEventQueue();

      container.read(networkStatusProvider.notifier).setOffline();

      await container
          .read(groupDmProvider.notifier)
          .sendMessage(groupId, 'Queued message');

      final key = 'pending_group_dms_user-1_org-1';

      expect((jsonDecode(stored[key]!) as Map)[groupId], ['Queued message']);

      expect(
        container.read(groupDmProvider).single.messages,
        contains('Queued message (Pending...)'),
      );

      verifyNever(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/group-dms/channels/group-1/threads',
          data: any(named: 'data'),
        ),
      );

      when(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/group-dms/channels/group-1/threads',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {},
          statusCode: 201,
        ),
      );

      container.read(networkStatusProvider.notifier).setOnline();

      await container.read(groupDmProvider.notifier).retryPendingMessages();

      expect(jsonDecode(stored[key]!), isEmpty);

      expect(
        container.read(groupDmProvider).single.messages,
        contains('Queued message'),
      );

      expect(
        container.read(groupDmProvider).single.messages,
        isNot(contains('Queued message (Pending...)')),
      );

      verify(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/group-dms/channels/group-1/threads',
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('failed server send preserves pending message for retry', () async {
      final groupId = await createGroup();
      await pumpEventQueue();

      final key = 'pending_group_dms_user-1_org-1';

      when(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/group-dms/channels/group-1/threads',
          data: any(named: 'data'),
        ),
      ).thenThrow(const ApiFailure(message: 'Server unavailable'));

      await container
          .read(groupDmProvider.notifier)
          .sendMessage(groupId, 'Do not lose me');

      expect((jsonDecode(stored[key]!) as Map)[groupId], ['Do not lose me']);

      expect(
        container.read(groupDmProvider).single.messages,
        contains('Do not lose me (Pending...)'),
      );

      when(
        () => mockApi.post<Map<String, dynamic>>(
          path: '/group-dms/channels/group-1/threads',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          data: {},
          statusCode: 201,
        ),
      );

      await container.read(groupDmProvider.notifier).retryPendingMessages();

      expect(jsonDecode(stored[key]!), isEmpty);

      expect(
        container.read(groupDmProvider).single.messages,
        contains('Do not lose me'),
      );
    });
  });
}
