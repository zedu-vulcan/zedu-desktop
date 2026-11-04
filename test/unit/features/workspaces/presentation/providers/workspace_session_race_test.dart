import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockApi extends Mock implements ApiBaseService {}

class _MemoryStorage extends SecureStorageService {
  String? token;

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String value, {bool persist = true}) async {
    token = value;
  }

  @override
  Future<void> deleteAccessToken() async => token = null;

  @override
  Future<Map<String, String>> readAll() async => {};
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
  currentOrg: 'org-$id',
  currentOrganisationSlug: 'org-$id',
  avatarUrl: '',
  defaultAvatarUrl: '',
);

ApiResponseModel<Map<String, dynamic>> _response(String id) => ApiResponseModel(
  statusCode: 200,
  data: {
    'data': [
      {'id': 'org-$id', 'name': 'Workspace $id'},
    ],
  },
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockAuthRepository authRepository;
  late _MockApi api;
  late ProviderContainer container;
  late AuthNotifier auth;
  late Completer<ApiResponseModel<Map<String, dynamic>>> oldResponse;
  late Completer<ApiResponseModel<Map<String, dynamic>>> newResponse;
  late int calls;

  setUp(() async {
    await locator.reset();
    final storage = _MemoryStorage();
    authRepository = _MockAuthRepository();
    api = _MockApi();
    oldResponse = Completer();
    newResponse = Completer();
    calls = 0;
    locator.registerSingleton<SecureStorageService>(storage);
    locator.registerSingleton<AuthInterceptor>(
      AuthInterceptor(storage: storage),
    );
    locator.registerSingleton<ApiBaseService>(api);
    locator.registerSingleton<AppConfig>(
      const AppConfig(
        apiBaseUrl: 'https://example.invalid/',
        usesMockData: false,
      ),
    );
    when(
      () => authRepository.verifyMagicLink(token: any(named: 'token')),
    ).thenAnswer((invocation) async {
      final id = invocation.namedArguments[#token] as String;
      return Success(
        AuthSession(
          user: _user(id),
          accessToken: 'fake-$id',
          accessTokenExpiresIn: DateTime(2027),
        ),
      );
    });
    when(
      () => api.get<Map<String, dynamic>>(path: '/users/organisations'),
    ).thenAnswer((_) {
      calls++;
      return calls == 1 ? oldResponse.future : newResponse.future;
    });
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
    auth = container.read(authNotifierProvider.notifier);
    await _flush();
    await auth.verifyMagicLink(token: 'A');
    final subscription = container.listen(workspaceProvider, (_, _) {});
    addTearDown(subscription.close);
    await _flush();
    expect(calls, 1);
  });

  tearDown(() async {
    container.dispose();
    await locator.reset();
  });

  Future<void> signInAgain(String id) async {
    await auth.logout();
    await auth.verifyMagicLink(token: id);
    container.read(workspaceProvider);
    await _flush();
    expect(calls, 2);
  }

  for (final id in ['B', 'A']) {
    test(
      'late success from old session does not replace session $id',
      () async {
        await signInAgain(id);
        newResponse.complete(_response(id));
        await _flush();
        oldResponse.complete(_response('old'));
        await _flush();

        final state = container.read(workspaceProvider);
        expect(container.read(authNotifierProvider).user?.id, id);
        expect(state.workspaces.map((w) => w.id), ['org-$id']);
        expect(state.selectedWorkspace?.id, 'org-$id');
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      },
    );
  }

  test('late failure from old session does not affect the new load', () async {
    await signInAgain('B');
    oldResponse.completeError(Exception('old request failed'));
    await _flush();
    expect(container.read(workspaceProvider).isLoading, isTrue);
    expect(container.read(workspaceProvider).errorMessage, isNull);

    newResponse.complete(_response('B'));
    await _flush();
    final state = container.read(workspaceProvider);
    expect(state.selectedWorkspace?.id, 'org-B');
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('late old success cannot stop the new session loading', () async {
    await signInAgain('B');
    oldResponse.complete(_response('old'));
    await _flush();
    expect(container.read(workspaceProvider).isLoading, isTrue);
    expect(container.read(workspaceProvider).workspaces, isEmpty);

    newResponse.complete(_response('B'));
    await _flush();
    expect(container.read(workspaceProvider).selectedWorkspace?.id, 'org-B');
  });

  test('late old failure cannot add an error after the new load', () async {
    await signInAgain('B');
    newResponse.complete(_response('B'));
    await _flush();
    oldResponse.completeError(Exception('old request failed'));
    await _flush();

    final state = container.read(workspaceProvider);
    expect(state.selectedWorkspace?.id, 'org-B');
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('current session can load, fail and retry', () async {
    oldResponse.complete(_response('A'));
    await _flush();
    expect(container.read(workspaceProvider).selectedWorkspace?.id, 'org-A');

    final refresh = container
        .read(workspaceProvider.notifier)
        .fetchWorkspaces();
    newResponse.completeError(Exception('current request failed'));
    await refresh;
    expect(
      container.read(workspaceProvider).errorMessage,
      WorkspaceNotifier.loadErrorMessage,
    );
    when(
      () => api.get<Map<String, dynamic>>(path: '/users/organisations'),
    ).thenAnswer((_) async => _response('A'));
    await container.read(workspaceProvider.notifier).fetchWorkspaces();
    expect(container.read(workspaceProvider).selectedWorkspace?.id, 'org-A');
    expect(container.read(workspaceProvider).errorMessage, isNull);
  });
}
