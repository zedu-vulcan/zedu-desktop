import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Fake notifier that avoids GetIt/locator setup while remaining type-compatible
// with authNotifierProvider (which is NotifierProvider<AuthNotifier, AuthState>).
class FakeSignUpAuthNotifier extends AuthNotifier {
  FakeSignUpAuthNotifier({
    AuthState initial = const AuthState(status: AuthStatus.unauthenticated),
    void Function(String username, String email, String password)? onSignUp,
    Future<void>? pendingSignUp,
  }) : _initial = initial,
       _onSignUp = onSignUp,
       _pendingSignUp = pendingSignUp;

  final AuthState _initial;
  final void Function(String username, String email, String password)?
  _onSignUp;
  final Future<void>? _pendingSignUp;

  @override
  AuthState build() => _initial;

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    _onSignUp?.call(username, email, password);
    await _pendingSignUp;
    state = state.copyWith(isLoading: false);
  }
}

Widget buildSignUpViewUnderTest({required FakeSignUpAuthNotifier notifier}) {
  return ProviderScope(
    overrides: [authNotifierProvider.overrideWith(() => notifier)],
    child: buildTestMaterialApp(const SignUpView()),
  );
}

void main() {
  group('SignUpView', () {
    Future<void> pumpDesktopSignUp(
      WidgetTester tester,
      FakeSignUpAuthNotifier notifier,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildSignUpViewUnderTest(notifier: notifier));
      await tester.pump();
    }

    Finder usernameField() => find.byType(TextFormField).at(0);
    Finder emailField() => find.byType(TextFormField).at(1);
    Finder passwordField() => find.byType(TextFormField).at(2);

    testWidgets('Enter in Password validates the form without signing up', (
      tester,
    ) async {
      var signUpCalls = 0;
      await pumpDesktopSignUp(
        tester,
        FakeSignUpAuthNotifier(onSignUp: (_, _, _) => signUpCalls++),
      );
      await tester.enterText(usernameField(), '');
      await tester.enterText(emailField(), 'invalid-email');
      await tester.enterText(passwordField(), 'short');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(
        find.text('Password must be at least 8 characters long'),
        findsOneWidget,
      );
      expect(signUpCalls, 0);
    });

    testWidgets('Enter in Password submits valid details once and permits '
        'retry', (tester) async {
      final pendingSignUp = Completer<void>();
      final attempts = <(String, String, String)>[];
      await pumpDesktopSignUp(
        tester,
        FakeSignUpAuthNotifier(
          onSignUp: (username, email, password) =>
              attempts.add((username, email, password)),
          pendingSignUp: pendingSignUp.future,
        ),
      );
      await tester.enterText(usernameField(), 'zeduuser');
      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'Secret123');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Refocus after each submission: Flutter's done action unfocuses the field.
      // Submit again before pumping to exercise the synchronous loading guard.
      await tester.tap(passwordField());
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(passwordField());
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(attempts, [('zeduuser', 'user@example.com', 'Secret123')]);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      pendingSignUp.complete();
      await tester.pumpAndSettle();
      await tester.tap(passwordField());
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(attempts, [
        ('zeduuser', 'user@example.com', 'Secret123'),
        ('zeduuser', 'user@example.com', 'Secret123'),
      ]);
    });

    testWidgets('Enter does not submit while sign-up is already loading', (
      tester,
    ) async {
      var signUpCalls = 0;
      await pumpDesktopSignUp(
        tester,
        FakeSignUpAuthNotifier(
          initial: const AuthState(
            status: AuthStatus.unauthenticated,
            isLoading: true,
          ),
          onSignUp: (_, _, _) => signUpCalls++,
        ),
      );
      await tester.enterText(usernameField(), 'zeduuser');
      await tester.enterText(emailField(), 'user@example.com');
      await tester.enterText(passwordField(), 'Secret123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(signUpCalls, 0);
    });
  });
}
