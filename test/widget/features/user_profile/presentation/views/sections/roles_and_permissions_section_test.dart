import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  testWidgets('the page title matches the "Roles & permissions" menu item', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestMaterialApp(
        const Scaffold(body: RolesAndPermissionsSection(roles: [])),
      ),
    );

    expect(find.text('Roles & permissions'), findsOneWidget);
    expect(find.text('Roles & Permissions'), findsNothing);
  });

  testWidgets('renders role description and arrow with theme tokens', (
    tester,
  ) async {
    const role = RolePermission(
      role: 'Admin',
      description: 'Full access to all settings and team management',
      permissions: ['all'],
    );

    await tester.pumpWidget(
      buildTestMaterialApp(
        const Scaffold(body: RolesAndPermissionsSection(roles: [role])),
      ),
    );

    final textWidget = tester.widget<Text>(find.text(role.description));
    final iconWidget = tester.widget<Icon>(
      find.byIcon(Icons.keyboard_arrow_right),
    );

    expect(textWidget.style?.color, equals(AppPalette.light.textSecondary));
    expect(iconWidget.color, equals(AppPalette.light.textHint));
  });
}
