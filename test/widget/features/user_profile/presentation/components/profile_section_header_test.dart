import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('section title and subtitle use the palette in ${brightness.name} mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(
            body: ProfileSectionHeader(
              title: 'Account',
              subtitle: 'Your profile',
            ),
          ),
        ),
      );

      final title = find.text('Account');
      expect(
        tester.widget<Text>(title).style?.color,
        tester.element(title).colors.textPrimary,
      );

      final subtitle = find.text('Your profile');
      expect(
        tester.widget<Text>(subtitle).style?.color,
        tester.element(subtitle).colors.textSecondary,
      );
    });
  }
}
