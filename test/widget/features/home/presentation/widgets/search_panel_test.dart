import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

// The panel hosts a TextField, so it needs a Material ancestor as well as the
// app shell it gets in production.
Widget hostPanel(Widget panel) => MaterialApp(home: Scaffold(body: panel));

void main() {
  group('SearchPanel', () {
    testWidgets('releases its text controller when removed from the tree', (
      tester,
    ) async {
      await tester.pumpWidget(hostPanel(SearchPanel(onClose: () {})));

      await tester.enterText(find.byType(TextField), 'release notes');
      await tester.pump();
      expect(find.text('release notes'), findsOneWidget);

      // Unmounting used to leave the controller and its listeners behind:
      // _SearchPanelState had no dispose() at all. The panel must now tear
      // itself down without throwing.
      await tester.pumpWidget(hostPanel(const SizedBox.shrink()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SearchPanel), findsNothing);
    });

    testWidgets('close button reports back through onClose', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        hostPanel(SearchPanel(onClose: () => closed = true)),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
    });
  });
}
