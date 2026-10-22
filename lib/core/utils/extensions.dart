import 'package:flutter/material.dart';
import 'package:zedu/core/theme/app_palette.dart';

extension AppPaletteX on BuildContext {
  AppPalette get colors => Theme.of(this).brightness == Brightness.light
      ? AppPalette.light
      : AppPalette.dark;
}

extension ThemeX on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
}
