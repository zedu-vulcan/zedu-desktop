import 'dart:convert';

/// A message the signed-in user kept for later.
///
/// The desktop app has no server-side bookmarks yet, so the message is copied
/// here and kept on this computer. [channelId] and [id] are what let the Saved
/// view open the conversation the message came from.
class SavedMessage {
  final String id;
  final String channelId;
  final String channelName;
  final String senderName;
  final String text;
  final DateTime savedAt;
  final DateTime? sentAt;

  const SavedMessage({
    required this.id,
    required this.channelId,
    required this.channelName,
    required this.senderName,
    required this.text,
    required this.savedAt,
    this.sentAt,
  });

  /// The message's identity within its conversation.
  String get key => '$channelId|$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    'channelId': channelId,
    'channelName': channelName,
    'senderName': senderName,
    'text': text,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'sentAt': sentAt?.millisecondsSinceEpoch,
  };

  factory SavedMessage.fromJson(Map<String, dynamic> json) => SavedMessage(
    id: json['id'] as String? ?? '',
    channelId: json['channelId'] as String? ?? '',
    channelName: json['channelName'] as String? ?? '',
    senderName: json['senderName'] as String? ?? '',
    text: json['text'] as String? ?? '',
    savedAt: DateTime.fromMillisecondsSinceEpoch(json['savedAt'] as int? ?? 0),
    sentAt: json['sentAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(json['sentAt'] as int)
        : null,
  );

  static String encodeAll(Iterable<SavedMessage> messages) => jsonEncode(
    messages.map((message) => message.toJson()).toList(growable: false),
  );

  static List<SavedMessage> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedMessage.fromJson)
          .where((message) => message.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      // A corrupt entry should not stop the rest of the app from loading.
      return const [];
    }
  }
}
