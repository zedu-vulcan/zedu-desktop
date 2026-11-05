import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  const imageFile = WorkspaceFile(
    id: 'f-img',
    name: 'photo.png',
    fileType: 'png',
    size: 1048576,
    link: 'https://example.com/photo.png',
  );

  const docFile = WorkspaceFile(
    id: 'f-doc',
    name: 'document.pdf',
    fileType: 'pdf',
    size: 2048,
    link: 'https://example.com/document.pdf',
  );

  testWidgets('renders file header with name, formatted size and type', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        const Scaffold(body: FilePreviewDialog(file: docFile)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('document.pdf'), findsNWidgets(2));
    expect(find.text('2 KB • PDF'), findsOneWidget);
    expect(find.byKey(const ValueKey('file-preview-close')), findsOneWidget);
  });

  testWidgets(
    'shows fallback message and open externally button for non-image files',
    (tester) async {
      var openedExternally = false;
      await tester.pumpWidget(
        buildTestMaterialApp(
          Scaffold(
            body: FilePreviewDialog(
              file: docFile,
              onOpenExternally: () => openedExternally = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Preview is not supported for this file type.'),
        findsOneWidget,
      );
      expect(find.text('Open externally'), findsOneWidget);

      await tester.tap(find.text('Open externally'));
      await tester.pumpAndSettle();

      expect(openedExternally, isTrue);
    },
  );

  testWidgets('closes the dialog when close button is tapped', (tester) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => FilePreviewDialog.show(context, file: imageFile),
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(FilePreviewDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('file-preview-close')));
    await tester.pumpAndSettle();

    expect(find.byType(FilePreviewDialog), findsNothing);
  });
}
