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
        .expand(_flattenGroup)
        .toList();
  }

  /// The backend groups hits by sender and channel; the UI wants one model per
  /// message. A flat payload (a message map with no `messages` list) is kept as
  /// one model so the parser stays useful for tests and other endpoints.
  Iterable<SearchResultModel> _flattenGroup(Map<String, dynamic> group) sync* {
    final rawMessages = group['messages'];
    if (rawMessages is! List) {
      yield SearchResultModel.fromJson(group);
      return;
    }

    final user = group['user'] is Map
        ? Map<String, dynamic>.from(group['user'] as Map)
        : const <String, dynamic>{};
    final channel = group['channel'] is Map
        ? Map<String, dynamic>.from(group['channel'] as Map)
        : const <String, dynamic>{};

    for (final rawMessage in rawMessages.whereType<Map<dynamic, dynamic>>()) {
      final message = Map<String, dynamic>.from(rawMessage);
      yield SearchResultModel(
        id:
            message['message_id']?.toString() ??
            message['id']?.toString() ??
            '',
        content:
            message['message']?.toString() ??
            message['content']?.toString() ??
            '',
        channelId:
            channel['channel_id']?.toString() ??
            channel['id']?.toString() ??
            '',
        channelName:
            channel['channel_name']?.toString() ??
            channel['name']?.toString() ??
            '',
        channelType: channel['channel_type']?.toString(),
        senderName:
            user['user_name']?.toString() ?? user['name']?.toString() ?? '',
        senderAvatarUrl: user['avatar_url']?.toString(),
        createdAt: DateTime.tryParse(
          message['timestamp']?.toString() ??
              message['created_at']?.toString() ??
              '',
        ),
        threadId: message['thread_id']?.toString(),
      );
    }
  }
}
