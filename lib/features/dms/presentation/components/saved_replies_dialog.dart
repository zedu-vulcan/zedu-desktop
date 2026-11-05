import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// A personal library of reusable messages. Selecting a reply returns it to the
/// composer; sending always remains a separate action.
class SavedRepliesDialog extends ConsumerStatefulWidget {
  const SavedRepliesDialog({super.key});

  @override
  ConsumerState<SavedRepliesDialog> createState() => _SavedRepliesDialogState();
}

class _SavedRepliesDialogState extends ConsumerState<SavedRepliesDialog> {
  final _search = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit({SavedReply? reply, String? title, String? body}) async {
    final userId = ref.read(authNotifierProvider).user?.id;
    final result = await showDialog<SavedReply>(
      context: context,
      builder: (_) => _ReplyEditor(reply: reply, title: title, body: body),
    );
    if (!mounted || result == null) return;
    if (ref.read(authNotifierProvider).user?.id != userId) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(savedRepliesProvider.notifier).save(result);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(SavedReply reply) async {
    final userId = ref.read(authNotifierProvider).user?.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved reply?'),
        content: Text('"${reply.title}" will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (ref.read(authNotifierProvider).user?.id != userId) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(savedRepliesProvider.notifier).delete(reply.id);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not delete. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final replies = ref.watch(savedRepliesProvider);
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    final query = _search.text.trim().toLowerCase();

    return Dialog(
      backgroundColor: colors.background,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 640),
        child: SizedBox(
          width: 680,
          height: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primaryBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved replies',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thoughtful messages, ready when you need them.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Private to your account on this device',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: colors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close saved replies',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search your replies',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed:
                          _busy ||
                              userId == null ||
                              userId.isEmpty ||
                              replies.isLoading ||
                              !replies.hasValue ||
                              replies.hasError
                          ? null
                          : () => _edit(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New reply'),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(_error!, style: TextStyle(color: colors.error)),
                ),
              Expanded(
                child: userId == null || userId.isEmpty
                    ? const Center(child: Text('Sign in to use saved replies.'))
                    : replies.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Could not load your saved replies.'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(savedRepliesProvider),
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                        data: (items) {
                          final matches = items
                              .where(
                                (reply) =>
                                    reply.title.toLowerCase().contains(query) ||
                                    reply.body.toLowerCase().contains(query),
                              )
                              .toList();
                          if (items.isEmpty) return _emptyState(colors);
                          if (matches.isEmpty) {
                            return const Center(
                              child: Text('No replies match your search.'),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                            itemCount: matches.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final reply = matches[index];
                              return Material(
                                color: colors.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: colors.divider),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _busy
                                      ? null
                                      : () => Navigator.pop(context, reply),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      12,
                                      8,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(9),
                                          decoration: BoxDecoration(
                                            color: colors.primaryBg,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            color: colors.primary,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reply.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: context
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: colors.textPrimary,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                reply.body,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: context
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          colors.textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Edit ${reply.title}',
                                          onPressed: _busy
                                              ? null
                                              : () => _edit(reply: reply),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 19,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Delete ${reply.title}',
                                          onPressed: _busy
                                              ? null
                                              : () => _delete(reply),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 19,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: colors.textHint,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Text(
                  'Choose a reply to insert it. You can edit it before sending.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(AppPalette colors) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_chat_unread_outlined,
              color: colors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'A little more time for what matters',
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save messages you write often, then make them your own each time.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Start with an idea',
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Friendly check-in'),
                onPressed: _busy
                    ? null
                    : () => _edit(
                        title: 'Friendly check-in',
                        body:
                            'Hi {{recipient}}, just checking in. How is everything going?',
                      ),
              ),
              ActionChip(
                label: const Text('Quick thank you'),
                onPressed: _busy
                    ? null
                    : () => _edit(
                        title: 'Quick thank you',
                        body:
                            'Thanks, {{recipient}}! I really appreciate your help.',
                      ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ReplyEditor extends StatefulWidget {
  const _ReplyEditor({this.reply, this.title, this.body});

  final SavedReply? reply;
  final String? title;
  final String? body;

  @override
  State<_ReplyEditor> createState() => _ReplyEditorState();
}

class _ReplyEditorState extends State<_ReplyEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.reply?.title ?? widget.title);
    _body = TextEditingController(text: widget.reply?.body ?? widget.body);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.reply == null ? 'New saved reply' : 'Edit saved reply',
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'e.g. Weekly check-in',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _body,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    hintText: 'Write the message you want to reuse',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a message.'
                      : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tip: {{recipient}} inserts the current conversation name.',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              SavedReply(
                id:
                    widget.reply?.id ??
                    DateTime.now().microsecondsSinceEpoch.toString(),
                title: _title.text.trim(),
                body: _body.text,
              ),
            );
          },
          child: const Text('Save reply'),
        ),
      ],
    );
  }
}
