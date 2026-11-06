import 'package:zedu/core/core.dart';
import 'package:zedu/features/dms/dms.dart';
import 'package:zedu/features/dms/presentation/components/composer/mention_suggestion_list.dart';

import '../../../../../../helpers/helpers.dart';

void main() {
  testWidgets('renders fallback circle avatar with primary theme color', (
    tester,
  ) async {
    final participant = DmParticipant(
      userId: 'u-1',
      username: 'alice',
      email: 'alice@example.com',
      avatarUrl: null,
    );

    await tester.pumpWidget(
      buildTestMaterialApp(
        Scaffold(
          body: MentionSuggestionList(
            suggestions: [participant],
            query: 'ali',
            colors: AppPalette.light,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    final avatarWidget = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatarWidget.backgroundColor, equals(AppPalette.light.primary));
  });
}
