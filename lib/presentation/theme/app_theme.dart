import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// `ThemeData` Murabbi — mode clair par défaut (P-4).
///
/// Le thème agrège uniquement les tokens DS (`AppColors`, `AppTypography`).
/// Aucun paramètre cosmétique ne doit être inline dans les widgets — tout
/// passe par `Theme.of(context)` ou directement les tokens.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accent,
      onPrimary: AppColors.bgSurface,
      secondary: AppColors.accentHover,
      onSecondary: AppColors.bgSurface,
      surface: AppColors.bgSurface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.bgSurface,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgPrimary,
      textTheme: const TextTheme(
        displayMedium: AppTypography.display,
        headlineLarge: AppTypography.h1,
        headlineMedium: AppTypography.h2,
        titleMedium: AppTypography.h3,
        bodyMedium: AppTypography.body,
        labelMedium: AppTypography.label,
        bodySmall: AppTypography.caption,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDefault,
        thickness: 0.5,
      ),
    );
  }
}
