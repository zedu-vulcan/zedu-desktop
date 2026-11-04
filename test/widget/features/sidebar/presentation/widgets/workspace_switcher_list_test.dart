import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [Workspace(id: '1', name: 'Acme', avatar: 'A')],
    selectedWorkspace: Workspace(id: '1', name: 'Acme', avatar: 'A'),
  );
}

Widget buildSwitcherUnderTest() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const Align(
                  alignment: Alignment.topLeft,
                  child: WorkspaceSwitcherList(),
                ),
              ),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRouter.profile,
        builder: (context, state) => const Scaffold(body: Text('Profile page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [workspaceProvider.overrideWith(FakeWorkspaceNotifier.new)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('WorkspaceSwitcherList', () {
    testWidgets('Settings button opens the settings page', (tester) async {
      // The test font is wider than Roboto and overflows the fixed-width menu.
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildSwitcherUnderTest());
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Profile page'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets(
      'renders safe initial without crash when workspace name is empty or starts with emoji',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 0.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(buildEmptySwitcherUnderTest());
        await tester.tap(find.text('Open menu'));
        await tester.pumpAndSettle();

        // Empty name falls back to 'W' without throwing RangeError
        expect(find.text('W'), findsWidgets);
        // Emoji name extracts complete first grapheme '🚀'
        expect(find.text('🚀'), findsOneWidget);
      },
    );

    testWidgets('caps large workspace unread counts at 99+', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(buildLargeUnreadSwitcherUnderTest());
      await tester.tap(find.text('Open menu'));
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
      expect(find.text('120'), findsNothing);
    });
  });
}

class FakeEmptyWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [
      Workspace(id: '1', name: '', avatar: ''),
      Workspace(id: '2', name: '🚀 Rocket', avatar: ''),
    ],
    selectedWorkspace: Workspace(id: '1', name: '', avatar: ''),
  );
}

Widget buildEmptySwitcherUnderTest() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const Align(
                  alignment: Alignment.topLeft,
                  child: WorkspaceSwitcherList(),
                ),
              ),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [workspaceProvider.overrideWith(FakeEmptyWorkspaceNotifier.new)],
    child: MaterialApp.router(routerConfig: router),
  );
}

class FakeLargeUnreadWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState(
    workspaces: [
      Workspace(id: '1', name: 'Acme', avatar: 'A', unreadCount: 120),
    ],
    selectedWorkspace: Workspace(
      id: '1',
      name: 'Acme',
      avatar: 'A',
      unreadCount: 120,
    ),
  );
}

Widget buildLargeUnreadSwitcherUnderTest() {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const Align(
                  alignment: Alignment.topLeft,
                  child: WorkspaceSwitcherList(),
                ),
              ),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      workspaceProvider.overrideWith(FakeLargeUnreadWorkspaceNotifier.new),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}
