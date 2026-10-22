import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/features/features.dart';

void main() {
  group('SecuritySection', () {
    testWidgets('renders empty state when sessions list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecuritySection(
                sessions: const [],
                isSaving: false,
                onChangePassword: ({required currentPassword, required newPassword}) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active sessions found'), findsOneWidget);
      expect(find.byIcon(Icons.devices_outlined), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('renders DataTable when sessions list has items', (tester) async {
      final sampleSessions = [
        const SecuritySession(
          device: 'Chrome on macOS',
          location: 'Lagos, Nigeria',
          date: 'Oct 22, 2026',
          lastActive: 'Just now',
          status: 'Active',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SecuritySection(
                sessions: sampleSessions,
                isSaving: false,
                onChangePassword: ({required currentPassword, required newPassword}) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active sessions found'), findsNothing);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Chrome on macOS'), findsOneWidget);
      expect(find.text('Lagos, Nigeria'), findsOneWidget);
    });
  });
}
