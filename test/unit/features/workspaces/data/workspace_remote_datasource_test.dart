import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  late MockApiBaseService api;
  late WorkspaceRemoteDataSourceImpl datasource;

  setUp(() {
    api = MockApiBaseService();
    datasource = WorkspaceRemoteDataSourceImpl(apiBaseService: api);
  });

  group('getOrganisations', () {
    test('requests the user organisations and parses them', () async {
      when(
        () => api.get<Map<String, dynamic>>(path: '/users/organisations'),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'org-1',
                'name': 'Cohort 13',
                'logo_url': 'https://cdn.zedu.test/logo.png',
                'channels_count': 7,
              },
            ],
          },
        ),
      );

      final workspaces = await datasource.getOrganisations();

      expect(workspaces.single.id, 'org-1');
      expect(workspaces.single.name, 'Cohort 13');
      expect(workspaces.single.avatar, 'https://cdn.zedu.test/logo.png');
      expect(workspaces.single.channelsCount, 7);
    });

    test('skips entries that are not maps', () async {
      when(
        () => api.get<Map<String, dynamic>>(path: '/users/organisations'),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': ['not-an-org', 42],
          },
        ),
      );

      expect(await datasource.getOrganisations(), isEmpty);
    });

    test('returns an empty list when the data key is missing', () async {
      when(
        () => api.get<Map<String, dynamic>>(path: '/users/organisations'),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {},
        ),
      );

      expect(await datasource.getOrganisations(), isEmpty);
    });
  });
}
