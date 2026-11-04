import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class _FakeSecureStorageService extends Fake implements SecureStorageService {
  final _values = <String, String>{};

  @override
  Future<String?> readData(String key) async => _values[key];

  @override
  Future<void> writeData(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> deleteValue(String key) async => _values.remove(key);
}

class _FakeUserProfileNotifier extends UserProfileNotifier {
  @override
  UserProfileState build() => const UserProfileState(teamMembers: []);
}

void main() {
  setUp(() {
    if (!locator.isRegistered<AppConfig>()) {
      locator.registerSingleton<AppConfig>(
        const AppConfig(apiBaseUrl: 'http://localhost', usesMockData: false),
      );
    }
    if (!locator.isRegistered<SecureStorageService>()) {
      locator.registerSingleton<SecureStorageService>(
        _FakeSecureStorageService(),
      );
    }
  });

  group('Composer Accessibility & Tooltip Tests', () {
    testWidgets(
      'DmMessageComposer renders send message tooltip and pointer cursor',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              dmDraftStoreProvider.overrideWith(
                (ref) => DmDraftStore(
                  _FakeSecureStorageService(),
                  userId: 'user-1',
                  orgId: 'org-1',
                ),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: DmMessageComposer(
                  recipientName: 'Ada',
                  channelId: 'dm-1',
                ),
              ),
            ),
          ),
        );

        final sendTooltipFinder = find.byTooltip('Send message');
        expect(sendTooltipFinder, findsOneWidget);

        final clickCursorFinder = find.descendant(
          of: sendTooltipFinder,
          matching: find.byWidgetPredicate(
            (w) => w is MouseRegion && w.cursor == SystemMouseCursors.click,
          ),
        );
        expect(clickCursorFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Home MessageComposer renders voice note and send message tooltips',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userProfileNotifierProvider.overrideWith(
                () => _FakeUserProfileNotifier(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: MessageComposer(
                  activeChat: ActiveChatState.generalChannel,
                  onSend: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.byTooltip('Record voice note'), findsOneWidget);

        final fieldFinder = find.byType(TextField);
        await tester.tap(fieldFinder);
        await tester.pump();
        await tester.enterText(fieldFinder, 'Hello team');
        await tester.pump();

        expect(find.byTooltip('Send message'), findsOneWidget);
      },
    );
  });
}
