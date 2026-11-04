import 'package:zedu/core/core.dart';

class MessageDeepLink {
  final String channelId;
  final String messageId;

  const MessageDeepLink({
    required this.channelId,
    required this.messageId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageDeepLink &&
          runtimeType == other.runtimeType &&
          channelId == other.channelId &&
          messageId == other.messageId;

  @override
  int get hashCode => channelId.hashCode ^ messageId.hashCode;
}

class MessageDeepLinkParser {
  const MessageDeepLinkParser._();

  static MessageDeepLink? parse(Uri uri) {
    // 1. Query parameters (?channelId=...&messageId=...)
    final qChannelId =
        uri.queryParameters['channelId'] ?? uri.queryParameters['channel_id'];
    final qMessageId =
        uri.queryParameters['messageId'] ?? uri.queryParameters['message_id'];
    if (qChannelId != null &&
        qChannelId.trim().isNotEmpty &&
        qMessageId != null &&
        qMessageId.trim().isNotEmpty) {
      return MessageDeepLink(
        channelId: qChannelId.trim(),
        messageId: qMessageId.trim(),
      );
    }

    // 2. Path segments: /channels/{channelId}/messages/{messageId} or /dms/{channelId}/messages/{messageId}
    final segments = uri.pathSegments;
    for (int i = 0; i < segments.length - 2; i++) {
      final prefix = segments[i].toLowerCase();
      if ((prefix == 'channels' ||
              prefix == 'dms' ||
              prefix == 'channel' ||
              prefix == 'dm') &&
          segments[i + 2].toLowerCase() == 'messages') {
        final channelId = segments[i + 1].trim();
        final messageId =
            i + 3 < segments.length ? segments[i + 3].trim() : null;
        if (channelId.isNotEmpty && messageId != null && messageId.isNotEmpty) {
          return MessageDeepLink(channelId: channelId, messageId: messageId);
        }
      }
    }

    // 3. /messages/{channelId}/{messageId}
    if (segments.length >= 3 && segments[0].toLowerCase() == 'messages') {
      final channelId = segments[1].trim();
      final messageId = segments[2].trim();
      if (channelId.isNotEmpty && messageId.isNotEmpty) {
        return MessageDeepLink(channelId: channelId, messageId: messageId);
      }
    }

    return null;
  }

  static String buildDeepLink({
    required String channelId,
    required String messageId,
  }) {
    return 'https://zedu.chat/channels/$channelId/messages/$messageId';
  }
}

final targetMessageIdProvider = StateProvider<String?>((ref) => null);
