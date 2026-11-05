import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class FilePreviewDialog extends StatelessWidget {
  const FilePreviewDialog({
    super.key,
    required this.file,
    this.onOpenExternally,
  });

  final WorkspaceFile file;
  final VoidCallback? onOpenExternally;

  static Future<void> show(
    BuildContext context, {
    required WorkspaceFile file,
    VoidCallback? onOpenExternally,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          FilePreviewDialog(file: file, onOpenExternally: onOpenExternally),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isImage = file.isImage && file.link.trim().isNotEmpty;

    return Dialog(
      backgroundColor: colors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.divider),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    file.isImage
                        ? Icons.image_outlined
                        : Icons.insert_drive_file_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: context.textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${formatFileSize(file.size)}${file.fileType.isNotEmpty ? ' • ${file.fileType.toUpperCase()}' : ''}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('file-preview-close'),
                    icon: Icon(Icons.close, color: colors.textHint, size: 20),
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: isImage
                    ? Center(
                        child: Image.network(
                          file.link,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _FallbackView(
                            file: file,
                            message: 'Could not load image preview.',
                            onOpen: onOpenExternally,
                          ),
                        ),
                      )
                    : _FallbackView(
                        file: file,
                        message: 'Preview is not supported for this file type.',
                        onOpen: onOpenExternally,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackView extends StatelessWidget {
  const _FallbackView({required this.file, required this.message, this.onOpen});

  final WorkspaceFile file;
  final String message;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 64,
            color: colors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            file.name,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onOpen != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open externally'),
            ),
          ],
        ],
      ),
    );
  }
}
