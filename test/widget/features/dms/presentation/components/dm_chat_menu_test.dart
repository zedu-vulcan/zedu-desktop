import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockChatHistory extends Mock implements ChatHistoryNotifier {}

class MockDraftStore extends Mock implements DmDraftStore {}

class FakeSignedInAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'user-self',
      firstName: 'Self',
      lastName: 'User',
      email: 'self@example.com',
      phone: '',
      username: 'selfuser',
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
  testWidgets('DM menu uses a white surface and opens the selected action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final history = MockChatHistory();
    when(() => history.messages).thenReturn([]);
    when(() => history.isLoading).thenReturn(false);
    when(() => history.hasMore).thenReturn(false);
    final drafts = MockDraftStore();
    when(() => drafts.load(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(FakeSignedInAuthNotifier.new),
          chatHistoryProvider('chat-1').overrideWith((ref) => history),
          dmDraftStoreProvider.overrideWith((ref) => drafts),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'chat-1',
                username: 'Menu Tester',
                participantId: 'user-1',
                previewMessage: '',
                unreadCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('View profile'), findsOneWidget);
    expect(find.text('Delete conversation'), findsOneWidget);
    final menuSurface = tester
        .widgetList<Material>(find.byType(Material))
        .where(
          (material) =>
              material.shape is RoundedRectangleBorder &&
              material.elevation == 8,
        );
    expect(menuSurface, hasLength(1));
    expect(menuSurface.single.color, AppPalette.light.onPrimary);
    expect(menuSurface.single.surfaceTintColor, Colors.transparent);
    expect(
      tester.widget<Text>(find.text('Delete conversation')).style?.color,
      AppPalette.light.error,
    );

    await tester.tap(find.text('View profile'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('User ID: user-1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('clicking Pinned messages opens the pinned messages dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final history = MockChatHistory();
    when(() => history.messages).thenReturn([]);
    when(() => history.isLoading).thenReturn(false);
    when(() => history.hasMore).thenReturn(false);
    final drafts = MockDraftStore();
    when(() => drafts.load(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(FakeSignedInAuthNotifier.new),
          chatHistoryProvider('chat-1').overrideWith((ref) => history),
          dmDraftStoreProvider.overrideWith((ref) => drafts),
        ],
        child: buildTestMaterialApp(
          Scaffold(
            body: DmChatArea(
              conversation: DmConversation(
                channelId: 'chat-1',
                username: 'Menu Tester',
                participantId: 'user-1',
                previewMessage: '',
                unreadCount: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Pinned messages'), findsOneWidget);
    await tester.tap(find.text('Pinned messages'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Menu Tester pinned messages'), findsOneWidget);
    expect(
      find.text('No pinned messages in this conversation.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
