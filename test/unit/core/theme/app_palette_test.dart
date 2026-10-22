import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/theme/app_palette.dart';
import 'package:zedu/core/theme/app_theme.dart';
import 'package:zedu/core/utils/extensions.dart';

Widget _buildPreviewWidget({required ThemeData theme, required GlobalKey key}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: RepaintBoundary(
        key: key,
        child: Builder(
          builder: (context) {
            final colors = context.colors;
            return Container(
              width: 800,
              height: 600,
              color: colors.background,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.sidebar,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Z',
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zedu Desktop - ${colors.brightness == Brightness.dark ? "Dark Mode" : "Light Mode"}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Theme Palette: context.colors (${colors.brightness.name})',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: colors.divider),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.primaryBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderOutline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.palette, color: colors.primary, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Palette Verification',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Background: #${colors.background.toARGB32().toRadixString(16).toUpperCase()} | Text: #${colors.textPrimary.toARGB32().toRadixString(16).toUpperCase()}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check),
                    label: Text(
                      colors.brightness == Brightness.dark
                          ? 'Dark Mode Palette Active'
                          : 'Light Mode Palette Active',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  group('AppPalette Constants', () {
    test('light palette has expected brightness and colors', () {
      expect(AppPalette.light.brightness, equals(Brightness.light));
      expect(AppPalette.light.primary, equals(const Color(0xFF6458F5)));
      expect(AppPalette.light.background, equals(const Color(0xFFFCFBFF)));
      expect(AppPalette.light.textPrimary, equals(const Color(0xFF1E1E1E)));
    });

    test('dark palette exists and has expected dark theme colors', () {
      expect(AppPalette.dark.brightness, equals(Brightness.dark));
      expect(AppPalette.dark.primary, equals(const Color(0xFF6458F5)));
      expect(AppPalette.dark.background, equals(const Color(0xFF121212)));
      expect(AppPalette.dark.textPrimary, equals(const Color(0xFFF5F5F5)));
      expect(AppPalette.dark.textSecondary, equals(const Color(0xFFA3A3A3)));
      expect(AppPalette.dark.sidebar, equals(const Color(0xFF1E1E2F)));
      expect(AppPalette.dark.borderOutline, equals(const Color(0xFF2A2A38)));
    });

    test('AppTheme exports both light and dark themes', () {
      expect(AppTheme.light.brightness, equals(Brightness.light));
      expect(AppTheme.dark.brightness, equals(Brightness.dark));
      expect(AppTheme.light.scaffoldBackgroundColor, equals(AppPalette.light.background));
      expect(AppTheme.dark.scaffoldBackgroundColor, equals(AppPalette.dark.background));
    });
  });

  group('AppPaletteX extension on BuildContext', () {
    testWidgets('returns AppPalette.light when theme brightness is light', (tester) async {
      late AppPalette capturedColors;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              capturedColors = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedColors.brightness, equals(Brightness.light));
      expect(capturedColors, equals(AppPalette.light));
      expect(capturedColors.background, equals(const Color(0xFFFCFBFF)));
    });

    testWidgets('returns AppPalette.dark when theme brightness is dark', (tester) async {
      late AppPalette capturedColors;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              capturedColors = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedColors.brightness, equals(Brightness.dark));
      expect(capturedColors, equals(AppPalette.dark));
      expect(capturedColors.background, equals(const Color(0xFF121212)));
    });

    testWidgets('generates light mode preview screenshot', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      final key = GlobalKey();
      await tester.pumpWidget(_buildPreviewWidget(theme: AppTheme.light, key: key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final dir = Directory('screenshots');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File('screenshots/01_light_mode_preview.png').writeAsBytesSync(bytes!.buffer.asUint8List());

      expect(File('screenshots/01_light_mode_preview.png').existsSync(), isTrue);
    });

    testWidgets('generates dark mode preview screenshot', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      final key = GlobalKey();
      await tester.pumpWidget(_buildPreviewWidget(theme: AppTheme.dark, key: key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final dir = Directory('screenshots');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      File('screenshots/02_dark_mode_preview.png').writeAsBytesSync(bytes!.buffer.asUint8List());

      expect(File('screenshots/02_dark_mode_preview.png').existsSync(), isTrue);
    });
  });
}
