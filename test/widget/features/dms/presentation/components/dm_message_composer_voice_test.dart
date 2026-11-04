import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';
import 'dm_message_composer_test.dart' show FakeSecureStorageService;

class MockVoiceChatHistory extends Mock implements ChatHistoryNotifier {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const recorderChannel = MethodChannel('com.llfbandit.record/messages');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late MockVoiceChatHistory history;
  late String? recordingPath;
  late String? eventChannel;
  late Completer<void> recorderDisposed;

  setUp(() {
    recordingPath = null;
    eventChannel = null;
    recorderDisposed = Completer<void>();
    history = MockVoiceChatHistory();
    when(
      () => history.sendMessage(
        any(),
        media: any(named: 'media'),
        isChannel: any(named: 'isChannel'),
      ),
    ).thenAnswer((_) async {});
    messenger.setMockMethodCallHandler(recorderChannel, (call) async {
      switch (call.method) {
        case 'create':
          final args = call.arguments as Map<Object?, Object?>;
          eventChannel = 'com.llfbandit.record/events/${args['recorderId']}';
          messenger.setMockMethodCallHandler(
            MethodChannel(eventChannel!),
            (_) async => null,
          );
          return null;
        case 'hasPermission':
          return true;
        case 'start':
          final args = call.arguments as Map<Object?, Object?>;
          recordingPath = args['path'] as String;
          return null;
        case 'stop':
          return recordingPath;
        case 'isRecording':
          return false;
        case 'dispose':
          recorderDisposed.complete();
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(recorderChannel, null);
    if (eventChannel != null) {
      messenger.setMockMethodCallHandler(MethodChannel(eventChannel!), null);
    }
  });

  Future<void> pumpComposer(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dmDraftStoreProvider.overrideWith(
            (ref) => DmDraftStore(
              FakeSecureStorageService(),
              userId: 'user-1',
              orgId: 'org-1',
            ),
          ),
          chatHistoryProvider('dm-1').overrideWith((ref) => history),
        ],
        child: buildTestMaterialApp(
          const Scaffold(
            body: DmMessageComposer(recipientName: 'Ada', channelId: 'dm-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color? sendColor(WidgetTester tester) =>
      tester.widget<Icon>(find.byIcon(Icons.send_rounded)).color;

  final inactiveColor = AppPalette.light.textHint.withValues(alpha: 0.55);

  Future<void> finishRecording(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Voice message'));
    await tester.pumpAndSettle();
    expect(sendColor(tester), inactiveColor);
    await tester.tap(find.byTooltip('Stop recording').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
  }

  Future<void> removeVoiceNote(WidgetTester tester) async {
    final removeButton = tester.widget<InkWell>(
      find.ancestor(
        of: find.byIcon(Icons.close_rounded),
        matching: find.byType(InkWell),
      ),
    );
    // Removal awaits file-system IO before it updates the composer state.
    await tester.runAsync(removeButton.onTap! as Future<void> Function());
    await tester.pumpAndSettle();
  }

  Future<void> disposeComposer(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await recorderDisposed.future;
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'finished voice note activates send; removing it deactivates send',
    (tester) async {
      await pumpComposer(tester);
      expect(sendColor(tester), inactiveColor);
      await finishRecording(tester);
      expect(sendColor(tester), AppPalette.light.primary);

      await removeVoiceNote(tester);
      expect(sendColor(tester), inactiveColor);
      await disposeComposer(tester);
    },
  );

  testWidgets('voice-only send submits audio and returns send to inactive', (
    tester,
  ) async {
    await pumpComposer(tester);
    await finishRecording(tester);
    expect(sendColor(tester), AppPalette.light.primary);
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    final media =
        verify(
              () => history.sendMessage(
                '',
                media: captureAny(named: 'media'),
                isChannel: false,
              ),
            ).captured.single
            as List<XFile>;
    expect(media.single.path, recordingPath);
    expect(media.single.mimeType, 'audio/mp4');
    expect(sendColor(tester), inactiveColor);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing);
    await disposeComposer(tester);
  });

  testWidgets('cancelling recording leaves send inactive', (tester) async {
    await pumpComposer(tester);
    await tester.tap(find.byTooltip('Voice message'));
    await tester.pumpAndSettle();
    final cancelButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Cancel'),
        matching: find.byType(IconButton),
      ),
    );
    await tester.runAsync(cancelButton.onPressed! as Future<void> Function());
    await tester.pumpAndSettle();
    expect(sendColor(tester), inactiveColor);
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing);
    await disposeComposer(tester);
  });

  testWidgets('text still activates send after removing a voice note', (
    tester,
  ) async {
    await pumpComposer(tester);
    await finishRecording(tester);
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pumpAndSettle();
    await removeVoiceNote(tester);
    expect(sendColor(tester), AppPalette.light.primary);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pumpAndSettle();
    expect(sendColor(tester), inactiveColor);
    await disposeComposer(tester);
  });

  testWidgets('a pending voice note does not activate an empty message edit', (
    tester,
  ) async {
    await pumpComposer(tester);
    await finishRecording(tester);
    tester
        .state<DmMessageComposerState>(find.byType(DmMessageComposer))
        .enterEditMode('message-1', '');
    await tester.pumpAndSettle();
    expect(sendColor(tester), inactiveColor);
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    verifyNever(() => history.saveEdit(any(), any()));
    await removeVoiceNote(tester);
    await disposeComposer(tester);
  });
}
