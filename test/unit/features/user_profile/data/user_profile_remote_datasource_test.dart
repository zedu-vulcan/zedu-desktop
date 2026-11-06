import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  group('UserProfileRemoteDataSourceImpl.deleteAccount (Ziki #584)', () {
    late MockApiBaseService api;
    late UserProfileRemoteDataSourceImpl datasource;

    setUp(() {
      api = MockApiBaseService();
      datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: 'http://test', usesMockData: false),
        apiBaseService: api,
      );
      when(
        () => api.delete<Map<String, dynamic>>(path: '/users/me'),
      ).thenAnswer(
        (_) async => ApiResponseModel<Map<String, dynamic>>(
          data: const <String, dynamic>{},
          statusCode: 200,
        ),
      );
    });

    test('deactivates the account with DELETE /users/me', () async {
      await datasource.deleteAccount();

      verify(
        () => api.delete<Map<String, dynamic>>(path: '/users/me'),
      ).called(1);
    });

    test('never calls the non-existent /profile/account route', () async {
      await datasource.deleteAccount();

      verifyNever(
        () => api.delete<Map<String, dynamic>>(path: '/profile/account'),
      );
    });
  });

  group('UserProfileRemoteDataSourceImpl.getTeamMembers', () {
    test('lists the organisation users with their real names', () async {
      final mockApi = MockApiBaseService();
      final datasource = UserProfileRemoteDataSourceImpl(
        config: const AppConfig(apiBaseUrl: '', usesMockData: false),
        apiBaseService: mockApi,
      );
      const orgId = '019700db-4e22-7f90-a20e-f9116291ef24';
      when(
        () => mockApi.get<Map<String, dynamic>>(path: any(named: 'path')),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': [
              {'id': 'u1', 'email': 'a@zedu.chat', 'full_name': 'Alice Ade'},
              {'id': 'u2', 'email': 'b@zedu.chat', 'username': 'bobby'},
              {'id': 'u3', 'email': 'carol@zedu.chat', 'full_name': ' '},
            ],
          },
        ),
      );

      final members = await datasource.getTeamMembers(orgId: orgId);

      verify(
        () => mockApi.get<Map<String, dynamic>>(
          path: '/organisations/$orgId/users',
        ),
      ).called(1);
      expect(members.map((m) => m.name), ['Alice Ade', 'bobby', 'carol']);
    });
  });
}
