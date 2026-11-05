import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class _MemoryStorage extends SecureStorageService {
  final values = <String, String>{};
  bool failWrite = false;
  Completer<void>? writeGate;

  @override
  Future<String?> readData(String key) async => values[key];

  @override
  Future<void> writeData(String key, String value) async {
    if (failWrite) throw StateError('storage unavailable');
    if (writeGate != null) await writeGate!.future;
    values[key] = value;
  }
}

User _user(String id) => User(
  id: id,
  firstName: id,
  lastName: 'Test',
  email: '$id@example.invalid',
  phone: '',
  username: id,
  isVerified: true,
  isOnboarded: true,
  createdAt: DateTime(2026),
  currentOrg: 'org',
  currentOrganisationSlug: 'org',
  avatarUrl: '',
  defaultAvatarUrl: '',
);

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, user: _user('A'));

  void switchTo(String id) =>
      state = AuthState(status: AuthStatus.authenticated, user: _user(id));
}

void main() {
  late _MemoryStorage storage;
  late ProviderContainer container;

  setUp(() async {
    await locator.reset();
    storage = _MemoryStorage();
    locator.registerSingleton<SecureStorageService>(storage);
    container = ProviderContainer(
      overrides: [authNotifierProvider.overrideWith(_Auth.new)],
      retry: (_, _) => null,
    );
  });

  tearDown(() async {
    container.dispose();
    await locator.reset();
  });

  test('create, edit and delete persist for the owning account', () async {
    expect(await container.read(savedRepliesProvider.future), isEmpty);
    final replies = container.read(savedRepliesProvider.notifier);
    await replies.save(
      const SavedReply(id: '1', title: 'Hello', body: 'Hi {{recipient}}'),
    );
    await replies.save(
      const SavedReply(id: '1', title: 'Updated', body: 'Hello again'),
    );
    expect(container.read(savedRepliesProvider).value!.single.title, 'Updated');

    container.invalidate(savedRepliesProvider);
    expect(
      (await container.read(savedRepliesProvider.future)).single.body,
      'Hello again',
    );
    await container.read(savedRepliesProvider.notifier).delete('1');
    container.invalidate(savedRepliesProvider);
    expect(await container.read(savedRepliesProvider.future), isEmpty);
  });

  test('replies stay separate across account changes', () async {
    await container.read(savedRepliesProvider.future);
    await container
        .read(savedRepliesProvider.notifier)
        .save(const SavedReply(id: '1', title: 'Private A', body: 'Only A'));
    (container.read(authNotifierProvider.notifier) as _Auth).switchTo('B');
    expect(await container.read(savedRepliesProvider.future), isEmpty);
    await container
        .read(savedRepliesProvider.notifier)
        .save(const SavedReply(id: '2', title: 'Private B', body: 'Only B'));
    (container.read(authNotifierProvider.notifier) as _Auth).switchTo('A');
    expect(
      (await container.read(savedRepliesProvider.future)).single.title,
      'Private A',
    );
  });

  test('a delayed write for A cannot replace B library', () async {
    await container.read(savedRepliesProvider.future);
    storage.writeGate = Completer<void>();
    final pending = container
        .read(savedRepliesProvider.notifier)
        .save(const SavedReply(id: '1', title: 'Private A', body: 'Only A'));
    (container.read(authNotifierProvider.notifier) as _Auth).switchTo('B');
    expect(await container.read(savedRepliesProvider.future), isEmpty);
    storage.writeGate!.complete();
    await pending;
    expect(container.read(savedRepliesProvider).value, isEmpty);
    (container.read(authNotifierProvider.notifier) as _Auth).switchTo('A');
    expect(
      (await container.read(savedRepliesProvider.future)).single.title,
      'Private A',
    );
  });

  test('failed writes leave the visible library unchanged', () async {
    await container.read(savedRepliesProvider.future);
    storage.failWrite = true;
    await expectLater(
      container
          .read(savedRepliesProvider.notifier)
          .save(const SavedReply(id: '1', title: 'Hello', body: 'Hello')),
      throwsStateError,
    );
    expect(container.read(savedRepliesProvider).value, isEmpty);
  });

  test(
    'a malformed stored library is reported rather than overwritten',
    () async {
      storage.values['saved_replies_A'] = '{broken';
      await expectLater(
        container.read(savedRepliesProvider.future),
        throwsFormatException,
      );
      expect(storage.values['saved_replies_A'], '{broken');
    },
  );

  test('the recipient placeholder is replaced without changing other text', () {
    expect(
      renderSavedReply('Hi {{recipient}}! {{other}}', recipient: 'Ada'),
      'Hi Ada! {{other}}',
    );
  });
}
