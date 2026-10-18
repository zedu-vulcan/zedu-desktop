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

    testWidgets(
      'clicking View all channels and switching to DMs tab on rail cleanly leaves directory',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(buildHomeViewUnderTest());
        await tester.pumpAndSettle();

        // Click "View all channels" in sidebar
        await tester.tap(find.text('View all channels'));
        await tester.pumpAndSettle();

        expect(find.text('Directories'), findsOneWidget);

        // Switch to DMs tab on rail
        await tester.tap(find.byIcon(Icons.chat_bubble_outline));
        await tester.pumpAndSettle();

        // Verify directory is dismissed in favor of DM area
        expect(find.text('Directories'), findsNothing);
        expect(find.text('Recent Messages'), findsOneWidget);

        // Switch back to Home tab on rail
        await tester.tap(find.byIcon(Icons.home_filled));
        await tester.pumpAndSettle();

        // Should return to channel view, not directory
        expect(find.text('Directories'), findsNothing);
        expect(find.text('# general'), findsWidgets);
      },
    );
  });
}
