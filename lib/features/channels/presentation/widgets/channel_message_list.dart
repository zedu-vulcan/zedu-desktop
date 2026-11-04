import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// The messages of a channel, newest at the bottom. Shows [empty] when the
/// channel has no messages yet.
class ChannelMessageList extends ConsumerWidget {
  const ChannelMessageList({
    super.key,
    required this.channelId,
    required this.empty,
  });

  final String channelId;
  final Widget empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(channelHistoryProvider(channelId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () =>
                  ref.invalidate(channelHistoryProvider(channelId)),
              child: const Text("Couldn't load messages. Retry"),
            ),
          ),
          data: (messages) => messages.isEmpty
              ? empty
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChannelMessageTile(
                      message: message,
                      channelId: channelId,
                      onCopyLink: message.id != null
                          ? () async {
                              final url = MessageDeepLinkParser.buildDeepLink(
                                channelId: channelId,
                                messageId: message.id!,
                              );
                              await Clipboard.setData(ClipboardData(text: url));
                              if (context.mounted) {
                                AppToastService.show(
                                  context,
                                  type: AppToastType.success,
                                  message: 'Link copied to clipboard',
                                );
                              }
                            }
                          : null,
                    );
                  },
                ),
        );
  }
}

class ChannelMessageTile extends ConsumerStatefulWidget {
  const ChannelMessageTile({
    super.key,
    required this.message,
    required this.channelId,
    this.onCopyLink,
  });

  final ChannelMessage message;
  final String channelId;
  final VoidCallback? onCopyLink;

  @override
  ConsumerState<ChannelMessageTile> createState() => _ChannelMessageTileState();
}

class _ChannelMessageTileState extends ConsumerState<ChannelMessageTile> {
  final _menuKey = GlobalKey<PopupMenuButtonState<String>>();
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = widget.message;
    final avatarUrl = message.avatarUrl;
    final time = message.createdAt;
    final trimmedName = message.senderName.trim();
    final initial = trimmedName.isNotEmpty
        ? trimmedName.characters.first.toUpperCase()
        : '?';

    final targetId = ref.watch(targetMessageIdProvider);
    final isTarget = targetId != null &&
        targetId.isNotEmpty &&
        message.id != null &&
        targetId == message.id;

    if (isTarget) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignment: 0.5,
        );
        ref.read(targetMessageIdProvider.notifier).state = null;
      });
    }

    final hasActions = widget.onCopyLink != null;

    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primary,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(initial, style: TextStyle(color: colors.onPrimary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
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
                    ),
                    if (hasActions)
                      Opacity(
                        opacity: _hovered ? 1 : 0,
                        child: PopupMenuButton<String>(
                          key: _menuKey,
                          tooltip: 'Message actions',
                          icon: const Icon(Icons.more_horiz, size: 18),
                          onSelected: (value) {
                            if (value == 'copy_link') {
                              widget.onCopyLink?.call();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'copy_link',
                              child: Text('Copy link'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  message.text,
                  style: TextStyle(fontSize: 15, color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (hasActions) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onSecondaryTap: () => _menuKey.currentState?.showButtonMenu(),
          onLongPress: () => _menuKey.currentState?.showButtonMenu(),
          child: tile,
        ),
      );
    }

    return tile;
  }
}
