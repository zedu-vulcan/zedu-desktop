import 'package:flutter/services.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockDraftStorage extends Mock implements SecureStorageService {}
class MockDmRepository extends Mock implements DmRepository {}

class FakeSecureStorageService extends Fake implements SecureStorageService {
  final _values = <String, String>{};

  @override
  Future<String?> readData(String key) async => _values[key];

  @override
  Future<void> writeData(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> deleteValue(String key) async => _values.remove(key);
}

Future<TextField> pumpComposer(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dmDraftStoreProvider.overrideWith(
          (ref) => DmDraftStore(FakeSecureStorageService()),
        ),
      ],
      child: buildTestMaterialApp(
        const Scaffold(
          body: DmMessageComposer(recipientName: 'Ada', channelId: 'dm-1'),
        ),
      ),
    ),
  );
  return tester.widget<TextField>(find.byType(TextField));
}

Future<void> typeAndPlaceCursorAtEnd(
  WidgetTester tester,
  TextField field,
  String text,
) async {
  await tester.enterText(find.byType(TextField), text);
  field.controller!.selection = TextSelection.collapsed(offset: text.length);
  await tester.pump();
}

/// Runs [body] against the composer, then empties it so the composer's
/// draft flush in `dispose` has nothing to save when the test unmounts it.
void composerTest(
  String description,
  Future<void> Function(WidgetTester tester, TextField field) body,
) {
  testWidgets(description, (tester) async {
    final field = await pumpComposer(tester);
    await body(tester, field);
    field.controller!.clear();
    await tester.pump(const Duration(milliseconds: 300));
  });
}

Future<void> tapDivider(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Divider'));
  // Let the composer's debounced draft save run.
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  const cases =
      <
        ({
          String name,
          String text,
          TextSelection selection,
          String expected,
          int caret,
        })
      >[
        (
          name: 'replaces a forward selection',
          text: 'Hello world',
          selection: TextSelection(baseOffset: 6, extentOffset: 11),
          expected: 'Hello 😀',
          caret: 8,
        ),
        (
          name: 'replaces a backward selection',
          text: 'Hello world',
          selection: TextSelection(baseOffset: 11, extentOffset: 6),
          expected: 'Hello 😀',
          caret: 8,
        ),
        (
          name: 'replaces the entire draft',
          text: 'Hello world',
          selection: TextSelection(baseOffset: 0, extentOffset: 11),
          expected: '😀',
          caret: 2,
        ),
        (
          name: 'inserts at a caret without removing adjacent text',
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 6),
          expected: 'Hello 😀world',
          caret: 8,
        ),
        (
          name: 'inserts at the beginning of a draft',
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 0),
          expected: '😀Hello world',
          caret: 2,
        ),
        (
          name: 'inserts at the end of a draft',
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 11),
          expected: 'Hello world😀',
          caret: 13,
        ),
        (
          name: 'inserts into an empty draft',
          text: '',
          selection: TextSelection.collapsed(offset: 0),
          expected: '😀',
          caret: 2,
        ),
        (
          name: 'preserves an emoji before the selected word',
          text: '😀 world',
          selection: TextSelection(baseOffset: 3, extentOffset: 8),
          expected: '😀 😀',
          caret: 5,
        ),
      ];

  for (final scenario in cases) {
    testWidgets('DM emoji picker ${scenario.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final storage = MockDraftStorage();
      when(() => storage.readData(any())).thenAnswer((_) async => null);
      when(() => storage.writeData(any(), any())).thenAnswer((_) async {});
      when(() => storage.deleteValue(any())).thenAnswer((_) async {});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dmDraftStoreProvider.overrideWith((ref) => DmDraftStore(storage)),
          ],
          child: buildTestMaterialApp(
            const Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: DmMessageComposer(
                  recipientName: 'Test recipient',
                  channelId: 'test-channel',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      final controller = tester.widget<TextField>(field).controller!;
      try {
        await tester.enterText(field, scenario.text);
        controller.selection = scenario.selection;
        await tester.pump();
        await tester.tap(find.byTooltip('Emoji'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('😀'));
        await tester.pumpAndSettle();

        expect(controller.text, scenario.expected);
        expect(
          controller.selection,
          TextSelection.collapsed(offset: scenario.caret),
        );
        expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      } finally {
        controller.clear();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }

  group('DmMessageComposer Divider button', () {
    composerTest('inserts a divider into an empty composer', (
      tester,
      field,
    ) async {
      await tapDivider(tester);

      expect(field.controller!.text, '---\n');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 4),
      );
    });

    composerTest(
      'puts a blank line before the divider so it is not read as a heading',
      (tester, field) async {
        await typeAndPlaceCursorAtEnd(tester, field, 'hello');

        await tapDivider(tester);

        expect(field.controller!.text, 'hello\n\n---\n');
        expect(
          field.controller!.selection,
          const TextSelection.collapsed(offset: 'hello\n\n---\n'.length),
        );
      },
    );

    composerTest('adds only one newline when the text already ends with one', (
      tester,
      field,
    ) async {
      await typeAndPlaceCursorAtEnd(tester, field, 'hello\n');

      await tapDivider(tester);

      expect(field.controller!.text, 'hello\n\n---\n');
    });

    composerTest('inserts after the selection without removing it', (
      tester,
      field,
    ) async {
      await tester.enterText(find.byType(TextField), 'hello world');
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );
      await tester.pump();

      await tapDivider(tester);

      expect(field.controller!.text, 'hello\n\n---\n world');
      expect(
        field.controller!.selection,
        const TextSelection.collapsed(offset: 'hello\n\n---\n'.length),
      );
    });
  });

  group('DmMessageComposer Up-arrow edit shortcut', () {
    late MockDmRepository mockDmRepo;

    setUp(() {
      mockDmRepo = MockDmRepository();
      when(() => mockDmRepo.editMessage(any(), content: any(named: 'content')))
          .thenAnswer((_) async {});
    });

    Future<TextField> pumpComposerWithMessages(
      WidgetTester tester, {
      required List<Map<String, dynamic>> messages,
    }) async {
      when(() => mockDmRepo.getMessages('dm-1', page: any(named: 'page')))
          .thenAnswer((_) async => messages);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dmDraftStoreProvider.overrideWith(
              (ref) => DmDraftStore(FakeSecureStorageService()),
            ),
            dmRepositoryProvider.overrideWithValue(mockDmRepo),
          ],
          child: buildTestMaterialApp(
            const Scaffold(
              body: DmMessageComposer(
                recipientName: 'Ada',
                channelId: 'dm-1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<TextField>(find.byType(TextField));
    }

    testWidgets(
      'Pressing Up arrow in an empty composer enters edit mode for last sent message',
      (tester) async {
        final field = await pumpComposerWithMessages(
          tester,
          messages: [
            {
              'id': 'msg-1',
              'content': 'Hllo team',
              'user_id': 'me',
              'status': 'sent',
            },
          ],
        );

        // Tap field to focus
        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Ensure composer is empty
        expect(field.controller!.text, isEmpty);

        // Press Up Arrow
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        // Composer should enter edit mode populated with last sent message content
        expect(field.controller!.text, 'Hllo team');
        expect(find.text('Editing message'), findsOneWidget);

        // Cleanup
        field.controller!.clear();
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'Pressing Up arrow when composer has text does not trigger edit mode',
      (tester) async {
        final field = await pumpComposerWithMessages(
          tester,
          messages: [
            {
              'id': 'msg-1',
              'content': 'Hllo team',
              'user_id': 'me',
              'status': 'sent',
            },
          ],
        );

        // Type some draft text
        await tester.enterText(find.byType(TextField), 'Drafting...');
        await tester.pump();

        // Press Up Arrow
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        // Composer text should remain as typed, not switched to edit mode
        expect(field.controller!.text, 'Drafting...');
        expect(find.text('Editing message'), findsNothing);

        // Cleanup
        field.controller!.clear();
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'Pressing Escape cancels edit mode and restores an empty composer',
      (tester) async {
        final field = await pumpComposerWithMessages(
          tester,
          messages: [
            {
              'id': 'msg-1',
              'content': 'Hllo team',
              'user_id': 'me',
              'status': 'sent',
            },
          ],
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Press Up Arrow to enter edit mode
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(find.text('Editing message'), findsOneWidget);
        expect(field.controller!.text, 'Hllo team');

        // Press Escape to cancel edit mode
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        // Edit mode should be cancelled and composer cleared
        expect(find.text('Editing message'), findsNothing);
        expect(field.controller!.text, isEmpty);

        // Cleanup
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'Pressing Up arrow does not trigger edit mode if user has sent no messages',
      (tester) async {
        final field = await pumpComposerWithMessages(
          tester,
          messages: [],
        );

        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Press Up Arrow
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();

        // Composer should stay empty, no edit mode
        expect(field.controller!.text, isEmpty);
        expect(find.text('Editing message'), findsNothing);

        // Cleanup
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
}

