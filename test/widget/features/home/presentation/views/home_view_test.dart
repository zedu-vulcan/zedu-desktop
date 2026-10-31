import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

void main() {
  group('ResizableSidebar', () {
    testWidgets(
      'respects the minimum and maximum width limits while dragging',
      (tester) async {
        await tester.pumpWidget(
          buildTestMaterialApp(
            Scaffold(
              body: ResizableSidebar(
                child: Container(
                  color: Colors.blue,
                  child: const Center(child: Text('Sidebar content')),
                ),
              ),
            ),
          ),
        );

        final resizableSidebar = find.byKey(
          const ValueKey('resizable-sidebar'),
        );
        final resizeHandle = find.byKey(
          const ValueKey('resizable-sidebar-handle'),
        );

        expect(tester.getSize(resizableSidebar).width, 320);

        final handleCenter = tester.getCenter(resizeHandle);
        final drag = await tester.startGesture(handleCenter);
        await drag.moveBy(const Offset(-1000, 0));
        await tester.pump();

        expect(
          tester.getSize(resizableSidebar).width,
          greaterThanOrEqualTo(ResizableSidebar.defaultMinWidth),
        );
        expect(
          tester.getSize(resizableSidebar).width,
          lessThanOrEqualTo(ResizableSidebar.defaultMaxWidth),
        );

        await drag.moveBy(const Offset(1000, 0));
        await tester.pump();

        expect(
          tester.getSize(resizableSidebar).width,
          lessThanOrEqualTo(ResizableSidebar.defaultMaxWidth),
        );
        expect(
          tester.getSize(resizableSidebar).width,
          greaterThanOrEqualTo(ResizableSidebar.defaultMinWidth),
        );
      },
    );
  });
}
