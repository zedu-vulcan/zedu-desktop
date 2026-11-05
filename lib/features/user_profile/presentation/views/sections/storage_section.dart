import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class StorageSection extends StatefulWidget {
  const StorageSection({
    super.key,
    this.storageService = const StorageService(),
  });

  final StorageService storageService;

  @override
  State<StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends State<StorageSection> {
  StorageUsage? _usage;
  bool _isLoading = true;
  bool _isClearingMedia = false;
  bool _isClearingAttachments = false;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    setState(() => _isLoading = true);
    final usage = await widget.storageService.calculateUsage();
    if (mounted) {
      setState(() {
        _usage = usage;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAndClearMedia() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Media Cache?'),
        content: const Text(
          'This will delete cached audio notes, images, and voice recordings. '
          'Your messages and account data will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isClearingMedia = true);
      await widget.storageService.clearMediaCache();
      await _loadUsage();
      if (mounted) {
        setState(() => _isClearingMedia = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media cache cleared.')),
        );
      }
    }
  }

  Future<void> _confirmAndClearAttachments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Attachments?'),
        content: const Text(
          'This will remove temporarily downloaded files and cached attachments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isClearingAttachments = true);
      await widget.storageService.clearAttachments();
      await _loadUsage();
      if (mounted) {
        setState(() => _isClearingAttachments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachments cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionHeader(
          title: 'Storage & Disk Usage',
          subtitle: 'View how much disk space Zedu uses and free up space.',
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.onPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Zedu Disk Usage',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoading
                            ? 'Calculating...'
                            : StorageService.formatBytes(_usage?.totalBytes ?? 0),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _loadUsage,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Recalculate usage',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: colors.divider),
              const SizedBox(height: 16),
              _StorageItemRow(
                icon: Icons.audio_file_outlined,
                title: 'Cached Media & Voice Recordings',
                subtitle:
                    'Temporary audio notes, voice recordings, and media thumbnails',
                size: _isLoading
                    ? '...'
                    : StorageService.formatBytes(_usage?.mediaBytes ?? 0),
                isClearing: _isClearingMedia,
                onClear: _confirmAndClearMedia,
              ),
              const SizedBox(height: 16),
              Divider(color: colors.divider),
              const SizedBox(height: 16),
              _StorageItemRow(
                icon: Icons.attach_file_outlined,
                title: 'Downloaded Attachments & Files',
                subtitle:
                    'Locally cached files and documents received in channels and DMs',
                size: _isLoading
                    ? '...'
                    : StorageService.formatBytes(
                        _usage?.attachmentsBytes ?? 0,
                      ),
                isClearing: _isClearingAttachments,
                onClear: _confirmAndClearAttachments,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StorageItemRow extends StatelessWidget {
  const _StorageItemRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.size,
    required this.isClearing,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String size;
  final bool isClearing;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: colors.textHint),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          size,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: isClearing ? null : onClear,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.error,
            side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
          ),
          child: isClearing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Clear'),
        ),
      ],
    );
  }
}
