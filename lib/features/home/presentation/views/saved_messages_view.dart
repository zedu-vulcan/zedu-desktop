import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// Every message the signed-in user kept, most recently saved first.
///
/// Tapping a row opens the conversation the message came from. The list is
/// local to this computer, so it works without a server round trip.
class SavedMessagesView extends ConsumerStatefulWidget {
  const SavedMessagesView({super.key});

  @override
  ConsumerState<SavedMessagesView> createState() => _SavedMessagesViewState();
}

class _SavedMessagesViewState extends ConsumerState<SavedMessagesView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(savedMessagesProvider).load());
  }

  void _open(SavedMessage message) {
    ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.home);
    ref
        .read(activeChatProvider.notifier)
        .selectChannel(
          message.channelName.isEmpty ? message.channelId : message.channelName,
          channelId: message.channelId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final store = ref.watch(savedMessagesProvider);
    final messages = store.items;

    return Container(
      color: colors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved messages',
                  style: context.textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Messages you kept, on this computer.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: !store.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? _EmptyState(colors: colors)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: colors.divider),
                    itemBuilder: (context, index) => _SavedMessageTile(
                      message: messages[index],
                      onTap: () => _open(messages[index]),
                      onRemove: () => ref
                          .read(savedMessagesProvider)
                          .remove(
                            messages[index].channelId,
                            messages[index].id,
                          ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});

  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 48, color: colors.textHint),
            const SizedBox(height: 12),
            Text(
              'Nothing saved yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Save a message from its menu to keep it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedMessageTile extends StatelessWidget {
  const _SavedMessageTile({
    required this.message,
    required this.onTap,
    required this.onRemove,
  });

  final SavedMessage message;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final channel = message.channelName.isEmpty
        ? message.channelId
        : message.channelName;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary,
              child: Text(
                avatarInitial(message.senderName),
                style: TextStyle(color: colors.onPrimary, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          message.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '#$channel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.bookmark_remove_outlined,
                size: 18,
                color: colors.textHint,
              ),
              splashRadius: 16,
              tooltip: 'Remove from saved',
            ),
          ],
        ),
      ),
    );
  }
}
