import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('MessageDeepLinkParser', () {
    test('parses query parameter format ?channelId=...&messageId=...', () {
      final uri = Uri.parse(
        'https://zedu.chat/open?channelId=chan123&messageId=msg456',
      );
      final link = MessageDeepLinkParser.parse(uri);
      expect(link, isNotNull);
      expect(link?.channelId, 'chan123');
      expect(link?.messageId, 'msg456');
    });

    test('parses query parameter format ?channel_id=...&message_id=...', () {
      final uri = Uri.parse(
        'https://zedu.chat/open?channel_id=chan999&message_id=msg888',
      );
      final link = MessageDeepLinkParser.parse(uri);
      expect(link, isNotNull);
      expect(link?.channelId, 'chan999');
      expect(link?.messageId, 'msg888');
    });

    test('parses path format /channels/{channelId}/messages/{messageId}', () {
      final uri = Uri.parse(
        'https://zedu.chat/channels/c_test_channel/messages/m_test_msg',
      );
      final link = MessageDeepLinkParser.parse(uri);
      expect(link, isNotNull);
      expect(link?.channelId, 'c_test_channel');
      expect(link?.messageId, 'm_test_msg');
    });

    test('parses path format /dms/{channelId}/messages/{messageId}', () {
      final uri = Uri.parse(
        'https://zedu.chat/dms/dm_channel_xyz/messages/dm_msg_123',
      );
      final link = MessageDeepLinkParser.parse(uri);
      expect(link, isNotNull);
      expect(link?.channelId, 'dm_channel_xyz');
      expect(link?.messageId, 'dm_msg_123');
    });

    test('parses path format /messages/{channelId}/{messageId}', () {
      final uri = Uri.parse(
        'https://zedu.chat/messages/my_channel/my_msg',
      );
      final link = MessageDeepLinkParser.parse(uri);
      expect(link, isNotNull);
      expect(link?.channelId, 'my_channel');
      expect(link?.messageId, 'my_msg');
    });

    test('returns null on invalid or unrelated uris', () {
      expect(MessageDeepLinkParser.parse(Uri.parse('https://zedu.chat/home')), isNull);
      expect(MessageDeepLinkParser.parse(Uri.parse('https://zedu.chat/channels/123')), isNull);
      expect(MessageDeepLinkParser.parse(Uri.parse('https://zedu.chat/dms')), isNull);
    });

    test('builds deep link correctly', () {
      final link = MessageDeepLinkParser.buildDeepLink(
        channelId: 'general',
        messageId: 'msg_001',
      );
      expect(link, 'https://zedu.chat/channels/general/messages/msg_001');

      final parsed = MessageDeepLinkParser.parse(Uri.parse(link));
      expect(parsed?.channelId, 'general');
      expect(parsed?.messageId, 'msg_001');
    });
  });
}
