import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class FakeCreditsNotifier extends CreditsNotifier {
  @override
  CreditsState build() => const CreditsState();

  @override
  Future<void> load({String? orgId}) async {}
}

class FakeChannelNotifier extends ChannelNotifier {
  FakeChannelNotifier(this.initialState);

  final ChannelState initialState;

  @override
  ChannelState build() => initialState;
}

Widget buildHomeViewUnderTest() {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(FakeAuthNotifier.new),
      creditsNotifierProvider.overrideWith(FakeCreditsNotifier.new),
      channelProvider.overrideWith(
        () => FakeChannelNotifier(
          ChannelState(
            channels: [
              Channel(
                id: '1',
                name: 'random',
                description: 'Random talk',
                organisationId: 'org1',
                ownerId: 'u1',
                membersCount: 15,
                isJoined: true,
              ),
            ],
          ),
        ),
      ),
    ],
    child: buildTestMaterialApp(const HomeView()),
  );
}

void main() {
  testWidgets('channel header ellipsis opens its action menu', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildHomeViewUnderTest());
    await tester.pumpAndSettle();

    final menuFinder = find.ancestor(
      of: find.byTooltip('More options'),
      matching: find.byType(PopupMenuButton<String>),
    );
    expect(menuFinder, findsOneWidget);
    expect(
      tester.widget<PopupMenuButton<String>>(menuFinder).tooltip,
      'More options',
    );

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Open channel details'), findsOneWidget);
    expect(find.text('Notification Settings'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Leave channel'), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Open channel details'), findsNothing);
  });

  group('HomeView View all channels navigation', () {
    testWidgets(
      'clicking View all channels in sidebar opens channel directory and selecting channel switches back',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildHomeViewUnderTest());
        await tester.pumpAndSettle();

        // Initially on general chat area
        expect(find.text('View all channels'), findsOneWidget);
        expect(find.text('# general'), findsWidgets);

        // Click "View all channels" in sidebar
        await tester.tap(find.text('View all channels'));
        await tester.pumpAndSettle();

        // Directories screen is shown
        expect(find.text('Directories'), findsOneWidget);
        expect(find.text('People'), findsWidgets);
        expect(find.text('Channels'), findsWidgets);
        expect(find.text('# random'), findsOneWidget);

        // Tap the channel item in the directory
        await tester.tap(find.text('# random'));
        await tester.pumpAndSettle();

        // Navigates back cleanly to chat area
        expect(find.text('Directories'), findsNothing);
      },
    );
  });
}
