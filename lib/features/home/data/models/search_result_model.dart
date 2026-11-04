/// One group of message hits returned by organisation-wide search.
///
/// The backend groups results by the message author and the channel, matching
/// the web app's `MessageSearchResult` shape.
class SearchResultModel {
  const SearchResultModel({
    required this.user,
    required this.messages,
    required this.channel,
  });

  final SearchResultUser user;
  final List<SearchResultMessage> messages;
  final SearchResultChannel channel;

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final rawChannel = json['channel'];
    final rawMessages = json['messages'];

    return SearchResultModel(
      user: SearchResultUser.fromJson(
        rawUser is Map ? Map<String, dynamic>.from(rawUser) : const {},
      ),
      messages: (rawMessages is List ? rawMessages : const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(SearchResultMessage.fromJson)
          .toList(),
      channel: SearchResultChannel.fromJson(
        rawChannel is Map ? Map<String, dynamic>.from(rawChannel) : const {},
      ),
    );
  }
}

class SearchResultUser {
  const SearchResultUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.defaultAvatarUrl,
    this.isDeactivated = false,
    this.isRestricted = false,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String? defaultAvatarUrl;
  final bool isDeactivated;
  final bool isRestricted;

  factory SearchResultUser.fromJson(Map<String, dynamic> json) =>
      SearchResultUser(
        id: json['user_id'] as String? ?? '',
        name: json['user_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        defaultAvatarUrl: json['default_avatar_url'] as String?,
        isDeactivated: json['is_deactivated'] as bool? ?? false,
        isRestricted: json['is_restricted'] as bool? ?? false,
      );
}

class SearchResultMessage {
  const SearchResultMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    this.threadId,
  });

  final String id;
  final String text;
  final String timestamp;
  final String? threadId;

  factory SearchResultMessage.fromJson(Map<String, dynamic> json) =>
      SearchResultMessage(
        id: json['message_id'] as String? ?? '',
        text: json['message'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
        threadId: json['thread_id'] as String?,
      );
}

class SearchResultChannel {
  const SearchResultChannel({required this.id, required this.name, this.type});

  final String id;
  final String name;
  final String? type;

  factory SearchResultChannel.fromJson(Map<String, dynamic> json) =>
      SearchResultChannel(
        id: json['channel_id'] as String? ?? '',
        name: json['channel_name'] as String? ?? '',
        type: json['channel_type'] as String?,
      );
}
