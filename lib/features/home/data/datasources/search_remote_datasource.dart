import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Organisation-wide message search, mirroring the web app's
/// `GET /search/organisation/:orgId` call.
abstract class SearchRemoteDataSource {
  Future<List<SearchResultModel>> searchMessages({
    required String orgId,
    required String query,
    String sortBy = 'relevance',
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiBaseService apiBaseService;

  SearchRemoteDataSourceImpl({required this.apiBaseService});

  @override
  Future<List<SearchResultModel>> searchMessages({
    required String orgId,
    required String query,
    String sortBy = 'relevance',
  }) async {
    final trimmed = query.trim();
    if (orgId.isEmpty || trimmed.isEmpty) return [];

    final response = await apiBaseService.get<Map<String, dynamic>>(
      path: '/search/organisation/$orgId',
      queryParameters: {'query': trimmed, 'sortBy': sortBy},
    );

    final data = response.data['data'];
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(SearchResultModel.fromJson)
        .toList();
  }
}
