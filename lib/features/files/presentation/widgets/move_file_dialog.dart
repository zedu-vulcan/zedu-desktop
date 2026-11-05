import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// "Move {file}": picks a folder and moves the file into it. A failure keeps
/// the dialog open with the reason.
class MoveFileDialog extends ConsumerStatefulWidget {
  const MoveFileDialog({super.key, required this.file});

  final WorkspaceFile file;

  /// Shows the dialog. Returns the folder the file was moved into.
  static Future<FileFolder?> show(
    BuildContext context, {
    required WorkspaceFile file,
  }) => showDialog<FileFolder>(
    context: context,
    builder: (_) => MoveFileDialog(file: file),
  );

  @override
  ConsumerState<MoveFileDialog> createState() => _MoveFileDialogState();
}

class _MoveFileDialogState extends ConsumerState<MoveFileDialog> {
  FileFolder? _selected;
  String? _error;

  Future<void> _move() async {
    final folder = _selected;
    if (folder == null) return;
    setState(() => _error = null);
    final error = await ref
        .read(fileMovesProvider.notifier)
        .move(widget.file, folder);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(folder);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMoving = ref.watch(
      fileMovesProvider.select((ids) => ids.contains(widget.file.id)),
    );
    final folders = ref.watch(moveTargetFoldersProvider);
    final textStyle = context.textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      color: colors.textSecondary,
    );

    Widget message(String text, {VoidCallback? onRetry}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(text, textAlign: TextAlign.center, style: textStyle),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );

    return Dialog(
      backgroundColor: colors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Move ${widget.file.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text('Choose a folder to move it to.', style: textStyle),
              const SizedBox(height: 12),
              Flexible(
                child: folders.when(
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    ),
                  ),
                  error: (_, _) => message(
                    'Could not load folders.',
                    onRetry: () => ref.invalidate(moveTargetFoldersProvider),
                  ),
                  data: (all) {
                    // The folder the file is already in is not a choice.
                    final choices = [
                      for (final f in all)
                        if (f.id != widget.file.folderId) f,
                    ];
                    if (choices.isEmpty) {
                      return message('No other folders yet. Create one first.');
                    }
                    return RadioGroup<String>(
                      groupValue: _selected?.id,
                      onChanged: (id) {
                        if (isMoving) return;
                        setState(() {
                          _selected = choices.firstWhere((f) => f.id == id);
                          _error = null;
                        });
                      },
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final folder in choices)
                            RadioListTile<String>(
                              value: folder.id,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: colors.primary,
                              secondary: Icon(
                                Icons.folder,
                                color: colors.primary,
                              ),
                              title: Text(
                                folder.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: colors.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isMoving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                    ),
                    onPressed: isMoving || _selected == null ? null : _move,
                    child: Text(isMoving ? 'Moving…' : 'Move'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
