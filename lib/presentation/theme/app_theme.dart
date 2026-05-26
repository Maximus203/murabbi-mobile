import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
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
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppIconSize.rg,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDefault,
        thickness: 0.5,
      ),
      // #146 : SnackBars cohérentes avec la palette sable/ocre. Le défaut
      // Material applique un fond noir « inversé » — on force le fond DS
      // (anthracite-brun) et un texte clair, y compris pour les SnackBars
      // créées hors `showAppSnackBar` (ex. shell de navigation).
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColors.bgSurface,
        ),
        actionTextColor: AppColors.accent,
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.accent,
      onPrimary: AppColorsDark.bgSurface,
      secondary: AppColorsDark.accentHover,
      onSecondary: AppColorsDark.bgSurface,
      surface: AppColorsDark.bgSurface,
      onSurface: AppColorsDark.textPrimary,
      error: AppColorsDark.danger,
      onError: AppColorsDark.bgSurface,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsDark.bgPrimary,
      textTheme: TextTheme(
        displayMedium: AppTypography.display.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        headlineLarge: AppTypography.h1.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        headlineMedium: AppTypography.h2.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        titleMedium: AppTypography.h3.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        bodyMedium: AppTypography.body.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        labelMedium: AppTypography.label.copyWith(
          color: AppColorsDark.textSecondary,
        ),
        bodySmall: AppTypography.caption.copyWith(
          color: AppColorsDark.textSecondary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColorsDark.textPrimary,
        size: AppIconSize.rg,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.borderDefault,
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.bgSurface,
        contentTextStyle: AppTypography.body.copyWith(
          color: AppColorsDark.textPrimary,
        ),
        actionTextColor: AppColorsDark.accent,
      ),
    );
  }
}
