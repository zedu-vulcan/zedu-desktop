import 'dart:convert';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _MemoryStorage extends SecureStorageService {
  final values = <String, String>{};

  @override
  Future<String?> readData(String key) async => values[key];

  @override
  Future<void> writeData(String key, String value) async => values[key] = value;

  @override
  Future<void> deleteValue(String key) async => values.remove(key);
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.invalid',
      phone: '',
      username: 'test',
      isVerified: true,
      isOnboarded: true,
      createdAt: DateTime(2026),
      currentOrg: 'org',
      currentOrganisationSlug: 'org',
      avatarUrl: '',
      defaultAvatarUrl: '',
    ),
  );
}

void main() {
  late _MemoryStorage storage;

  setUp(() async {
    await locator.reset();
    storage = _MemoryStorage();
    locator.registerSingleton<SecureStorageService>(storage);
  });

  tearDown(() async => locator.reset());

  Future<void> pumpComposer(
    WidgetTester tester, {
    bool isChannel = false,
    ValueChanged<String>? onSend,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          dmDraftStoreProvider.overrideWith(
            (ref) => DmDraftStore(storage, userId: 'user-1', orgId: 'org'),
          ),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmMessageComposer(
              recipientName: isChannel ? '#general' : 'Ada',
              channelId: 'conversation-1',
              isChannel: isChannel,
              onSend: onSend,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final isChannel in [false, true]) {
    testWidgets(
      'insert a saved reply into ${isChannel ? 'a channel' : 'a DM'} without sending',
      (tester) async {
        storage.values['saved_replies_user-1'] = jsonEncode([
          {'id': '1', 'title': 'Welcome', 'body': 'Hello {{recipient}}'},
        ]);
        var sent = 0;
        await pumpComposer(tester, isChannel: isChannel, onSend: (_) => sent++);
        final composer = tester.widget<TextField>(find.byType(TextField));
        await tester.enterText(find.byType(TextField), 'Before X after');
        composer.controller!.selection = const TextSelection(
          baseOffset: 7,
          extentOffset: 8,
        );
        await tester.tap(find.byTooltip('Saved replies'));
        await tester.pumpAndSettle();
        expect(find.text('Welcome'), findsOneWidget);
        await tester.tap(find.text('Welcome'));
        await tester.pumpAndSettle();

        expect(
          composer.controller!.text,
          'Before Hello ${isChannel ? '#general' : 'Ada'} after',
        );
        expect(sent, 0);
        expect(find.text('Saved replies'), findsNothing);
        composer.controller!.clear();
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  }

  testWidgets('create, search, edit and delete a reply', (tester) async {
    await pumpComposer(tester);
    await tester.tap(find.byTooltip('Saved replies'));
    await tester.pumpAndSettle();
    expect(find.text('A little more time for what matters'), findsOneWidget);
    await tester.tap(find.text('New reply'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Project update');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Hi {{recipient}}, here is my update.',
    );
    await tester.tap(find.text('Save reply'));
    await tester.pumpAndSettle();
    expect(find.text('Project update'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'not found');
    await tester.pump();
    expect(find.text('No replies match your search.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'project');
    await tester.pump();
    await tester.tap(find.byTooltip('Edit Project update'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Weekly update');
    await tester.tap(find.text('Save reply'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'weekly');
    await tester.pump();
    expect(find.text('Weekly update'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Weekly update'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('A little more time for what matters'), findsOneWidget);
    expect(jsonDecode(storage.values['saved_replies_user-1']!), isEmpty);
  });
}
