import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/theme/app_theme.dart';
import 'package:zedu/features/home/presentation/providers/group_dm_provider.dart';
import 'package:zedu/features/home/presentation/widgets/group_details_panel.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('GroupDetailsPanel Tooltips & Accessibility Tests', () {
    const testGroup = GroupDM(
      id: 'group-1',
      name: 'Engineering Team',
      members: [],
    );

    testWidgets('renders close details and edit name tooltips', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GroupDetailsPanel(
            group: testGroup,
            onClose: () {},
            onRename: (_) {},
            onLeave: () {},
          ),
        ),
      );

      // Verify header close button tooltip
      expect(find.byTooltip('Close details'), findsOneWidget);

      // Verify edit group name button tooltip
      expect(find.byTooltip('Edit group name'), findsOneWidget);
    });

    testWidgets('shows save name tooltip when editing group name', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          GroupDetailsPanel(
            group: testGroup,
            onClose: () {},
            onRename: (_) {},
            onLeave: () {},
          ),
        ),
      );

      // Tap edit button to enter editing mode
      await tester.tap(find.byTooltip('Edit group name'));
      await tester.pumpAndSettle();

      // Verify save name button tooltip appears
      expect(find.byTooltip('Save name'), findsOneWidget);
    });
  });
}
