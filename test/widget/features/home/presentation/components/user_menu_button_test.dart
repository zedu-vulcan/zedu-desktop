import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._user);
  final User? _user;

  @override
  AuthState build() => AuthState(
    status: _user != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated,
    user: _user,
  );
}

void main() {
  group('UserMenuButton', () {
    testWidgets('uses SystemMouseCursors.click for desktop hover affordance', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: buildTestMaterialApp(
            const Scaffold(body: Center(child: UserMenuButton())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mouseRegionFinder = find.descendant(
        of: find.byType(UserMenuButton),
        matching: find.byType(MouseRegion),
      );
      expect(mouseRegionFinder, findsOneWidget);

      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
      expect(mouseRegion.cursor, SystemMouseCursors.click);
    });

    testWidgets('tapping UserMenuButton opens UserMenuDialog', (tester) async {
      final user = User(
        id: 'u1',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        phone: '',
        username: 'test',
        isVerified: true,
        isOnboarded: true,
        createdAt: DateTime(2026, 1, 1),
        currentOrg: 'o1',
        currentOrganisationSlug: 'slug',
        avatarUrl: '',
        defaultAvatarUrl: '',
        status: const UserStatus(online: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => FakeAuthNotifier(user)),
            orgCreditBalanceProvider.overrideWithValue(0),
          ],
          child: buildTestMaterialApp(
            const Scaffold(body: Center(child: UserMenuButton())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UserMenuButton));
      await tester.pumpAndSettle();

      expect(find.byType(UserMenuDialog), findsOneWidget);
    });
  });
}
