import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// In-memory storage so tests don't touch the platform keychain.
class FakeSecureStorageService extends SecureStorageService {
  final values = <String, String>{};

  @override
  Future<void> saveAccessToken(String token) async =>
      values['access_token'] = token;

  @override
  Future<String?> getAccessToken() async => values['access_token'];

  @override
  Future<void> deleteAccessToken() async => values.remove('access_token');

  @override
  Future<void> setSessionOnly(bool sessionOnly) async => sessionOnly
      ? values['session_only'] = 'true'
      : values.remove('session_only');

  @override
  Future<bool> isSessionOnly() async => values['session_only'] == 'true';
}

final _user = User(
  id: '1',
  firstName: 'Ada',
  lastName: 'Lovelace',
  email: 'ada@example.com',
  phone: '',
  username: 'ada',
  isVerified: true,
  isOnboarded: true,
  createdAt: DateTime(2026),
  currentOrg: '',
  currentOrganisationSlug: '',
  avatarUrl: '',
  defaultAvatarUrl: '',
);

void main() {
  late MockAuthRepository repository;
  late FakeSecureStorageService storage;

  setUp(() {
    repository = MockAuthRepository();
    storage = FakeSecureStorageService();
    locator
      ..registerSingleton<SecureStorageService>(storage)
      ..registerSingleton<AuthInterceptor>(AuthInterceptor(storage: storage));
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => Success(
        AuthSession(
          user: _user,
          accessToken: 'token',
          accessTokenExpiresIn: DateTime(2027),
        ),
      ),
    );
    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => Success(_user));
  });

  tearDown(locator.reset);

  // Each container is a fresh app launch reading the same storage.
  Future<ProviderContainer> launchApp() async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.read(authNotifierProvider);
    await pumpEventQueue();
    return container;
  }

  Future<void> logIn({required bool rememberMe}) async {
    final container = await launchApp();
    await container
        .read(authNotifierProvider.notifier)
        .login(
          email: 'ada@example.com',
          password: 'Secret123',
          rememberMe: rememberMe,
        );
    expect(
      container.read(authNotifierProvider).status,
      AuthStatus.authenticated,
    );
  }

  group('AuthNotifier remember me', () {
    test('restores the session on next launch when ticked', () async {
      await logIn(rememberMe: true);

      final relaunch = await launchApp();

      expect(
        relaunch.read(authNotifierProvider).status,
        AuthStatus.authenticated,
      );
      expect(storage.values['access_token'], 'token');
    });

    test('signs out on next launch when unticked', () async {
      await logIn(rememberMe: false);

      final relaunch = await launchApp();

      expect(
        relaunch.read(authNotifierProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(storage.values, isEmpty);
    });

    test('logout clears the session-only flag', () async {
      final container = await launchApp();
      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.login(
        email: 'ada@example.com',
        password: 'Secret123',
        rememberMe: false,
      );

      await notifier.logout();

      expect(storage.values, isEmpty);
    });
  });
}
