import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/home/data/datasources/saved_messages_store.dart';
import 'package:zedu/features/home/data/models/saved_message.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

SavedMessage _message({
  String id = 'm-1',
  String channelId = 'ch-1',
  String text = 'hello',
  DateTime? savedAt,
}) => SavedMessage(
  id: id,
  channelId: channelId,
  channelName: 'general',
  senderName: 'Ada',
  text: text,
  savedAt: savedAt ?? DateTime(2026, 11, 6, 12),
);

void main() {
  group('SavedMessagesStore', () {
    late MockSecureStorageService storage;
    late Map<String, String> values;

    setUp(() {
      storage = MockSecureStorageService();
      values = <String, String>{};

      when(() => storage.readData(any())).thenAnswer((invocation) async {
        final key = invocation.positionalArguments[0] as String;
        return values[key];
      });

      when(() => storage.writeData(any(), any())).thenAnswer((
        invocation,
      ) async {
        final key = invocation.positionalArguments[0] as String;
        final value = invocation.positionalArguments[1] as String;
        values[key] = value;
      });

      when(() => storage.deleteValue(any())).thenAnswer((invocation) async {
        final key = invocation.positionalArguments[0] as String;
        values.remove(key);
      });

      when(() => storage.readAll()).thenAnswer((_) async => {...values});
    });

    SavedMessagesStore buildStore({
      String userId = 'user-1',
      String orgId = 'org-1',
    }) => SavedMessagesStore(storage, userId: userId, orgId: orgId);

    test('saves a message and reports it as saved', () async {
      final store = buildStore();

      await store.save(_message());

      expect(store.contains('ch-1', 'm-1'), isTrue);
      expect(store.items, hasLength(1));
      expect(store.items.single.text, 'hello');
      expect(values['saved_messages_user-1_org-1'], isNotNull);
    });

    test('saving the same message twice does not duplicate it', () async {
      final store = buildStore();

      await store.save(_message(text: 'first'));
      await store.save(_message(text: 'edited'));

      expect(store.items, hasLength(1));
      expect(store.items.single.text, 'edited');
    });

    test(
      'the same message id in another channel is a different entry',
      () async {
        final store = buildStore();

        await store.save(_message(channelId: 'ch-1'));
        await store.save(_message(channelId: 'ch-2'));

        expect(store.items, hasLength(2));
      },
    );

    test('removes a saved message', () async {
      final store = buildStore();
      await store.save(_message());

      await store.remove('ch-1', 'm-1');

      expect(store.contains('ch-1', 'm-1'), isFalse);
      expect(store.items, isEmpty);
    });

    test('toggle saves then unsaves', () async {
      final store = buildStore();

      expect(await store.toggle(_message()), isTrue);
      expect(store.contains('ch-1', 'm-1'), isTrue);

      expect(await store.toggle(_message()), isFalse);
      expect(store.contains('ch-1', 'm-1'), isFalse);
    });

    test('lists the most recently saved first', () async {
      final store = buildStore();

      await store.save(_message(id: 'old', savedAt: DateTime(2026, 11, 1)));
      await store.save(_message(id: 'new', savedAt: DateTime(2026, 11, 6)));

      expect(store.items.map((message) => message.id), ['new', 'old']);
    });

    test('reads saved messages back from storage', () async {
      final first = buildStore();
      await first.save(_message(id: 'm-1'));
      await first.save(_message(id: 'm-2'));

      final second = buildStore();
      await second.load();

      expect(second.items, hasLength(2));
      expect(second.contains('ch-1', 'm-2'), isTrue);
    });

    test('keeps each user and org separate', () async {
      final mine = buildStore(userId: 'user-1', orgId: 'org-1');
      await mine.save(_message());

      final otherUser = buildStore(userId: 'user-2', orgId: 'org-1');
      await otherUser.load();
      expect(otherUser.items, isEmpty);

      final otherOrg = buildStore(userId: 'user-1', orgId: 'org-2');
      await otherOrg.load();
      expect(otherOrg.items, isEmpty);
    });

    test('ignores a corrupt stored list instead of throwing', () async {
      values['saved_messages_user-1_org-1'] = 'not json';

      final store = buildStore();
      await store.load();

      expect(store.items, isEmpty);
    });

    test('deleteAllForUser removes every org for that user only', () async {
      values['saved_messages_user-1_org-1'] = '[]';
      values['saved_messages_user-1_org-2'] = '[]';
      values['saved_messages_user-2_org-1'] = '[]';
      values['dm_draft_user-1_org-1_ch-1'] = 'keep';

      await SavedMessagesStore.deleteAllForUser(storage, 'user-1');

      expect(values.keys, [
        'saved_messages_user-2_org-1',
        'dm_draft_user-1_org-1_ch-1',
      ]);
    });
  });
}
