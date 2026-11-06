import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The messages of a channel, newest at the bottom. Shows [empty] when the
/// channel has no messages yet.
class ChannelMessageList extends ConsumerWidget {
  const ChannelMessageList({
    super.key,
    required this.channelId,
    required this.empty,
    this.channelName,
  });

  final String channelId;
  final Widget empty;

  /// Shown on a saved message so the Saved view can name its conversation.
  final String? channelName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatHistory = ref.watch(chatHistoryProvider(channelId));
    final pendingMessages = chatHistory.messages
        .where(
          (m) =>
              m['status'] != null &&
              (m['channel_id'] == channelId || m['is_channel'] == true),
        )
        .map(
          (m) => ChannelMessage(
            id: m['id']?.toString(),
            senderName: (m['sender_name'] as String?)?.isNotEmpty == true
                ? m['sender_name'] as String
                : chatHistory.currentUserName,
            avatarUrl: (m['avatar_url'] as String?)?.isNotEmpty == true
                ? m['avatar_url'] as String
                : chatHistory.currentUserAvatarUrl,
            text: m['content']?.toString() ?? '',
            createdAt: DateTime.tryParse(
              m['created_at']?.toString() ?? '',
            )?.toLocal(),
            status: m['status']?.toString(),
          ),
        )
        .toList();

    return ref
        .watch(channelHistoryProvider(channelId))
        .when(
          loading: () => pendingMessages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _buildList(context, ref, pendingMessages),
          error: (_, _) => pendingMessages.isEmpty
              ? Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(channelHistoryProvider(channelId)),
                    child: const Text("Couldn't load messages. Retry"),
                  ),
                )
              : _buildList(context, ref, pendingMessages),
          data: (serverMessages) {
            final allMessages = [...pendingMessages, ...serverMessages];
            return allMessages.isEmpty
                ? empty
                : _buildList(context, ref, allMessages);
          },
        );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<ChannelMessage> messages,
  ) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ChannelMessageTile(
          message: message,
          channelId: channelId,
          channelName: channelName,
          onRetry: message.id != null
              ? () => ref
                    .read(chatHistoryProvider(channelId))
                    .retryMessage(message.id!)
              : null,
        );
      },
    );
  }
}

class ChannelMessageTile extends ConsumerStatefulWidget {
  const ChannelMessageTile({
    super.key,
    required this.message,
    required this.channelId,
    this.channelName,
    this.onRetry,
  });

  final ChannelMessage message;
  final String channelId;
  final String? channelName;
  final VoidCallback? onRetry;

  @override
  ConsumerState<ChannelMessageTile> createState() => _ChannelMessageTileState();
}

class _ChannelMessageTileState extends ConsumerState<ChannelMessageTile> {
  bool _hovering = false;

  ChannelMessage get message => widget.message;

  Future<void> _toggleSaved() async {
    final id = message.id;
    if (id == null) return;

    final store = ref.read(savedMessagesProvider);
    // Read what is already on disk first, so saving doesn't replace it.
    await store.load();
    await store.toggle(
      SavedMessage(
        id: id,
        channelId: widget.channelId,
        channelName: widget.channelName ?? '',
        senderName: message.senderName,
        text: message.text,
        savedAt: DateTime.now(),
        sentAt: message.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final avatarUrl = message.avatarUrl;
    final time = message.createdAt;
    final initial = avatarInitial(message.senderName);
    final status = message.status;
    final savedId = message.id;
    final isSaved =
        savedId != null &&
        ref.watch(savedMessagesProvider).contains(widget.channelId, savedId);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(initial, style: TextStyle(color: colors.onPrimary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: message.senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                      children: [
                        if (time != null)
                          TextSpan(
                            text:
                                '  ${TimeOfDay.fromDateTime(time).format(context)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  MessageLinkScope(
                    builder: (context, links) => SelectableText.rich(
                      links.span(
                        message.text,
                        TextStyle(fontSize: 15, color: colors.textPrimary),
                      ),
                    ),
                  ),
                  if (status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: status == 'failed'
                          ? GestureDetector(
                              onTap: widget.onRetry,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 13,
                                    color: colors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Failed – Tap to retry',
                                    style: TextStyle(
                                      color: colors.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              status == 'sending' ? 'Sending...' : '',
                              style: TextStyle(
                                color: colors.textHint,
                                fontSize: 11,
                              ),
                            ),
                    ),
                ],
              ),
            ),
            if (savedId != null && (_hovering || isSaved))
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  onPressed: _toggleSaved,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: isSaved ? colors.primary : colors.textHint,
                  ),
                  splashRadius: 16,
                  tooltip: isSaved ? 'Remove from saved' : 'Save message',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
