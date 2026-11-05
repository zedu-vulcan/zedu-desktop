import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('StorageSection widget tests (#2556)', () {
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      when(() => mockStorageService.calculateUsage()).thenAnswer(
        (_) async => const StorageUsage(
          mediaBytes: 1024 * 1024 * 15, // 15 MB
          attachmentsBytes: 1024 * 1024 * 10, // 10 MB
        ),
      );
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StorageSection(storageService: mockStorageService),
          ),
        ),
      );
    }

    testWidgets('renders StorageSection with calculated disk usage and rows', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Storage & Disk Usage'), findsOneWidget);
      expect(find.text('Total Zedu Disk Usage'), findsOneWidget);
      expect(find.text('25.0 MB'), findsOneWidget);
      expect(find.text('Cached Media & Voice Recordings'), findsOneWidget);
      expect(find.text('15.0 MB'), findsOneWidget);
      expect(find.text('Downloaded Attachments & Files'), findsOneWidget);
      expect(find.text('10.0 MB'), findsOneWidget);
      expect(find.text('Clear'), findsNWidgets(2));
    });

    testWidgets('tapping Clear on Media Cache shows confirmation dialog and clears upon confirm', (tester) async {
      when(() => mockStorageService.clearMediaCache()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap first Clear button (Media Cache)
      await tester.tap(find.text('Clear').first);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Clear Media Cache?'), findsOneWidget);
      expect(
        find.text(
          'This will delete cached audio notes, images, and voice recordings. Your messages and account data will remain intact.',
        ),
        findsOneWidget,
      );

      // Tap confirm Clear button in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Clear'));
      await tester.pumpAndSettle();

      verify(() => mockStorageService.clearMediaCache()).called(1);
      expect(find.text('Media cache cleared.'), findsOneWidget);
    });

    testWidgets('tapping Clear on Attachments shows confirmation dialog and clears upon confirm', (tester) async {
      when(() => mockStorageService.clearAttachments()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap second Clear button (Attachments)
      await tester.tap(find.text('Clear').last);
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Clear Attachments?'), findsOneWidget);
      expect(
        find.text(
          'This will remove temporarily downloaded files and cached attachments.',
        ),
        findsOneWidget,
      );

      // Tap confirm Clear button in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Clear'));
      await tester.pumpAndSettle();

      verify(() => mockStorageService.clearAttachments()).called(1);
      expect(find.text('Attachments cleared.'), findsOneWidget);
    });
  });
}
