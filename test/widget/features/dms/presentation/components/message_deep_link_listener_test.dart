import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockAppLinks extends Mock implements AppLinks {}

class FakeWorkspaceNotifier extends WorkspaceNotifier {
  @override
  WorkspaceState build() => const WorkspaceState();
}

class FakeDmListNotifier extends DmListNotifier {
  final List<DmConversation> conversations;
  FakeDmListNotifier(this.conversations);

  @override
  Future<List<DmConversation>> build() async => conversations;
}

void main() {
  group('MessageDeepLinkListener', () {
    late MockAppLinks mockAppLinks;
    late StreamController<Uri> linkController;

    setUp(() {
      mockAppLinks = MockAppLinks();
      linkController = StreamController<Uri>.broadcast();

      when(
        () => mockAppLinks.uriLinkStream,
      ).thenAnswer((_) => linkController.stream);
    });

    tearDown(() async {
      await linkController.close();
    });

    testWidgets('processes incoming message deep link and switches channel/message', (
      tester,
    ) async {
      when(() => mockAppLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('https://zedu.chat/channels/general/messages/msg-456'),
      );

      final container = ProviderContainer(
        overrides: [
          workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MessageDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(container.read(targetMessageIdProvider), 'msg-456');
      expect(container.read(homeSidebarProvider), HomeSidebarType.home);
      expect(container.read(activeChatProvider).id, 'general');
    });

    testWidgets('processes incoming message deep link for DM conversation', (
      tester,
    ) async {
      when(() => mockAppLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('https://zedu.chat/dms/dm_chan_123/messages/msg-789'),
      );

      final testDm = DmConversation(
        channelId: 'dm_chan_123',
        username: 'Bob',
        participantId: 'user_bob',
        previewMessage: 'hi',
        unreadCount: 0,
      );

      final container = ProviderContainer(
        overrides: [
          workspaceProvider.overrideWith(FakeWorkspaceNotifier.new),
          dmListProvider.overrideWith(() => FakeDmListNotifier([testDm])),
        ],
      );

      // Initialize provider
      await container.read(dmListProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: MessageDeepLinkListener(
              appLinks: mockAppLinks,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(container.read(targetMessageIdProvider), 'msg-789');
      expect(container.read(homeSidebarProvider), HomeSidebarType.dms);
      expect(container.read(selectedDmProvider)?.channelId, 'dm_chan_123');
    });
  });
}
