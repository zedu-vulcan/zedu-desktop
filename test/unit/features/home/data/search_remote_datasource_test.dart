import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../helpers/helpers.dart';

class MockApiBaseService extends Mock implements ApiBaseService {}

void main() {
  late MockApiBaseService api;
  late SearchRemoteDataSourceImpl datasource;

  setUp(() {
    api = MockApiBaseService();
    datasource = SearchRemoteDataSourceImpl(apiBaseService: api);
  });

  group('searchMessages', () {
    test('sends the org, query and sort and parses grouped results', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: '/search/organisation/org-1',
          queryParameters: {'query': 'deploy', 'sortBy': 'newest'},
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': [
              {
                'user': {
                  'user_id': 'u-1',
                  'user_name': 'Ada Lovelace',
                  'avatar_url': 'https://cdn.zedu.test/ada.png',
                },
                'messages': [
                  {
                    'message_id': 'm-1',
                    'thread_id': 't-1',
                    'message': 'Deploy is green',
                    'timestamp': '2026-11-04T10:00:00Z',
                  },
                ],
                'channel': {
                  'channel_id': 'c-1',
                  'channel_name': 'engineering',
                  'channel_type': 'public',
                },
              },
            ],
          },
        ),
      );

      final results = await datasource.searchMessages(
        orgId: 'org-1',
        query: 'deploy',
        sortBy: 'newest',
      );

      final result = results.single;
      expect(result.id, 'm-1');
      expect(result.content, 'Deploy is green');
      expect(result.senderName, 'Ada Lovelace');
      expect(result.senderAvatarUrl, 'https://cdn.zedu.test/ada.png');
      expect(result.channelId, 'c-1');
      expect(result.channelName, 'engineering');
      expect(result.channelType, 'public');
      expect(result.threadId, 't-1');
      expect(result.createdAt, DateTime.parse('2026-11-04T10:00:00Z'));
    });

    test('defaults the sort to relevance and trims the query', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: '/search/organisation/org-1',
          queryParameters: {'query': 'deploy', 'sortBy': 'relevance'},
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {'data': <dynamic>[]},
        ),
      );

      final results = await datasource.searchMessages(
        orgId: 'org-1',
        query: '  deploy  ',
      );

      expect(results, isEmpty);
      verify(
        () => api.get<Map<String, dynamic>>(
          path: '/search/organisation/org-1',
          queryParameters: {'query': 'deploy', 'sortBy': 'relevance'},
        ),
      ).called(1);
    });

    test('returns an empty list for an empty org or query', () async {
      expect(
        await datasource.searchMessages(orgId: '', query: 'deploy'),
        isEmpty,
      );
      expect(
        await datasource.searchMessages(orgId: 'org-1', query: '   '),
        isEmpty,
      );
      verifyNever(
        () => api.get<Map<String, dynamic>>(
          path: any(named: 'path'),
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    });

    test('returns an empty list when the body has no data list', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: '/search/organisation/org-1',
          queryParameters: {'query': 'deploy', 'sortBy': 'relevance'},
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {'data': null},
        ),
      );

      expect(
        await datasource.searchMessages(orgId: 'org-1', query: 'deploy'),
        isEmpty,
      );
    });

    test('tolerates missing nested fields', () async {
      when(
        () => api.get<Map<String, dynamic>>(
          path: '/search/organisation/org-1',
          queryParameters: {'query': 'deploy', 'sortBy': 'relevance'},
        ),
      ).thenAnswer(
        (_) async => const ApiResponseModel<Map<String, dynamic>>(
          statusCode: 200,
          data: {
            'data': [
              {'user': null, 'messages': null, 'channel': null},
            ],
          },
        ),
      );

      final result = (await datasource.searchMessages(
        orgId: 'org-1',
        query: 'deploy',
      )).single;

      expect(result.id, '');
      expect(result.content, '');
      expect(result.senderName, '');
      expect(result.channelId, '');
    });
  });
}
