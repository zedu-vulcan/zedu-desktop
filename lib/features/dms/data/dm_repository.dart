import 'package:zedu/core/core.dart';

import '../domain/dm_conversation.dart';

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final apiClient = locator<ApiBaseService>();
  return DmRepository(apiClient);
});

class DmRepository {
  static const int pageSize = 20;

  final ApiBaseService _apiClient;

  DmRepository(this._apiClient);

  Future<List<DmConversation>> getConversations({
    required String orgId,
    int page = 1,
    bool recentDm = false,
    String? search,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/organisations/$orgId/dms',
      queryParameters: {
        'page': page,
        'limit': pageSize,
        'recent_dm': recentDm,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response.data;
    final rawList = data['data'];
    final list = (rawList is List ? rawList : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DmConversation.fromJson)
        .toList();

    list.sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));

    return list;
  }

  Future<List<Map<String, dynamic>>> getMessages(
    String channelId, {
    int page = 1,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/channels/$channelId/messages',
      queryParameters: {'page': page, 'limit': pageSize},
    );

    final data = response.data;
    final rawMessages = data['messages'] ?? data['data'];
    final messages = rawMessages is Map<String, dynamic>
        ? rawMessages['messages'] ?? rawMessages['data']
        : rawMessages;

    if (messages is! List) return const [];

    return messages
        .whereType<Map<dynamic, dynamic>>()
        .map((message) => Map<String, dynamic>.from(message))
        .toList();
  }

  Future<void> sendMessage(
    String channelId,
    String content, {
    List<XFile>? media,
    List<dynamic>? mentions,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      path: '/channels/$channelId/messages',
      data: {
        "content": content,
        if (media != null && media.isNotEmpty)
          "media": media.map(_mediaPayloadFromFile).toList(),
        ...?(mentions != null ? {'mentions': mentions} : null),
      },
    );
  }

  Map<String, dynamic> _mediaPayloadFromFile(XFile file) {
    return {
      'name': file.name,
      'path': file.path,
      if (file.mimeType != null) 'mime_type': file.mimeType,
    };
  }

  Future<void> editMessage(
    String channelId, {
    required String content,
    String? threadId,
    List<Map<String, dynamic>>? media,
    List<Map<String, dynamic>>? mentions,
  }) async {
    await _apiClient.put<Map<String, dynamic>>(
      path: '/dms/messages/$channelId',
      data: {
        'content': content,
        ...?(threadId != null ? {'thread_id': threadId} : null),
        ...?(media != null ? {'media': media} : null),
        ...?(mentions != null ? {'mentions': mentions} : null),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getPinnedMessages(String channelId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      path: '/channels/pin/$channelId',
    );
    final rawPins = response.data['data'];
    if (rawPins is! List || rawPins.isEmpty) return const [];

    final pins = rawPins
        .whereType<Map<dynamic, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final threadById = <String, Map<String, dynamic>>{};
    final needsLookup = pins.any(
      (p) => (p['message'] ?? p['content'])?.toString().trim().isEmpty ?? true,
    );

    if (needsLookup) {
      try {
        final threadsRes = await _apiClient.get<Map<String, dynamic>>(
          path: '/dms/channels/$channelId/threads',
          queryParameters: {'page': 1, 'limit': 50},
        );
        final rawThreads = threadsRes.data['data'];
        if (rawThreads is List) {
          for (final item in rawThreads.whereType<Map<dynamic, dynamic>>()) {
            final map = Map<String, dynamic>.from(item);
            final tid = map['thread_id']?.toString() ?? '';
            final mid = map['id']?.toString() ?? '';
            if (tid.isNotEmpty) threadById[tid] = map;
            if (mid.isNotEmpty) threadById[mid] = map;
          }
        }
      } catch (_) {}
    }

    return pins.map((pin) {
      final id =
          (pin['id'] ?? pin['thread_id'] ?? pin['message_id'])?.toString() ??
          '';
      final matched = threadById[id];
      return <String, dynamic>{...pin, ...?matched, 'id': id};
    }).toList();
  }
}
