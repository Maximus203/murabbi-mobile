import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

void main() {
  group('AppTheme.light — surfaces & couleurs', () {
    final theme = AppTheme.light();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('Brightness.light (P-4 mobile par défaut clair)', () {
      expect(theme.brightness, Brightness.light);
    });

    test('scaffoldBackgroundColor = bgPrimary', () {
      expect(theme.scaffoldBackgroundColor, AppColors.bgPrimary);
    });

    test('colorScheme.primary = accent', () {
      expect(theme.colorScheme.primary, AppColors.accent);
    });

    test('colorScheme.surface = bgSurface', () {
      expect(theme.colorScheme.surface, AppColors.bgSurface);
    });

    test('colorScheme.error = danger', () {
      expect(theme.colorScheme.error, AppColors.danger);
    });
  });
}
