import 'dart:async';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MessageDeepLinkListener extends ConsumerStatefulWidget {
  const MessageDeepLinkListener({
    super.key,
    required this.child,
    this.appLinks,
  });

  final Widget child;
  final AppLinks? appLinks;

  @override
  ConsumerState<MessageDeepLinkListener> createState() =>
      _MessageDeepLinkListenerState();
}

class _MessageDeepLinkListenerState
    extends ConsumerState<MessageDeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  static const _tag = 'MessageDeepLinkListener';

  @override
  void initState() {
    super.initState();
    _appLinks = widget.appLinks ?? AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (error) {
      AppLogger.w('Failed to read initial deep link: $error', tag: _tag);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.w('Deep link stream error: $error', tag: _tag);
      },
    );
  }

  void _handleUri(Uri uri) {
    final link = MessageDeepLinkParser.parse(uri);
    if (link == null) return;

    AppLogger.i(
      'Processing message deep link for channel: ${link.channelId}, message: ${link.messageId}',
      tag: _tag,
    );

    // Set target message id for scrolling
    ref.read(targetMessageIdProvider.notifier).state = link.messageId;

    // Check if channelId matches a DM conversation or channel
    final dms = ref.read(dmListProvider).value ?? const [];
    DmConversation? matchedDm;
    for (final dm in dms) {
      if (dm.channelId == link.channelId) {
        matchedDm = dm;
        break;
      }
    }

    if (matchedDm != null) {
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.dms);
      ref.read(selectedDmProvider.notifier).select(matchedDm);
    } else {
      // Switch to channel
      ref.read(homeSidebarProvider.notifier).setType(HomeSidebarType.home);
      ref.read(activeChatProvider.notifier).selectChannel(link.channelId);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
