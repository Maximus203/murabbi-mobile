import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

/// Typographie Murabbi — Geist + Geist Mono + Noto Sans Arabic uniquement (P-3).
///
/// Source de vérité : DS sheet § Typographie.
///
/// Les fichiers TTF sont bundlés dans `assets/fonts/` et déclarés dans
/// `pubspec.yaml > flutter.fonts` (closes #97). Familles disponibles :
/// - `Geist` (Regular 400, Medium 500, SemiBold 600)
/// - `Geist Mono` (Regular 400, Medium 500)
/// - `Noto Sans Arabic` (Regular 400, Medium 500)
class AppTypography {
  AppTypography._();

  /// Famille principale — corps de texte, titres latins.
  static const String _geist = 'Geist';

  /// Famille mono — chiffres scoring, timer, captions Geist Mono.
  static const String _geistMono = 'Geist Mono';

  /// Famille arabe — noms de prières, dhikr.
  static const String _notoArabic = 'Noto Sans Arabic';

  /// Display XL 64 / Geist Mono Medium — countdown timer.
  static const TextStyle displayXl = TextStyle(
    fontFamily: _geistMono,
    fontSize: 64,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  /// Display LG 56 / Geist Mono Medium — grand chiffre objectif.
  static const TextStyle displayLg = TextStyle(
    fontFamily: _geistMono,
    fontSize: 56,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  /// Display MD 40 / Geist Mono Medium — affichage nombre de section.
  static const TextStyle displayMd = TextStyle(
    fontFamily: _geistMono,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  /// @Deprecated Utilisé nulle part — même taille/poids que [h1] avec un
  /// letterSpacing minime différent (-0.5 vs -0.3). Utiliser [h1].
  /// Conservé pour ne pas casser un éventuel code externe.
  @Deprecated('Utiliser AppTypography.h1 à la place')
  static const TextStyle displaySm = TextStyle(
    fontFamily: _geist,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Display 42 / Geist Mono Medium / -1px tracking.
  static const TextStyle display = TextStyle(
    fontFamily: _geistMono,
    fontSize: 42,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  /// H1 32 / Geist SemiBold / -0.3px — titre d'écran (pseudo, nom de prière).
  static const TextStyle h1 = TextStyle(
    fontFamily: _geist,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// H2 22 / Geist SemiBold — sous-titre de section.
  static const TextStyle h2 = TextStyle(
    fontFamily: _geist,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// H3 17 / Geist Medium — titre de carte.
  static const TextStyle h3 = TextStyle(
    fontFamily: _geist,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Body 16 / Geist Regular — texte courant.
  static const TextStyle body = TextStyle(
    fontFamily: _geist,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Label 12 / Geist Medium — UPPERCASE attendu côté usage.
  static const TextStyle label = TextStyle(
    fontFamily: _geist,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  /// Caption 12 / Geist Regular.
  static const TextStyle caption = TextStyle(
    fontFamily: _geist,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Arabic 22 / Noto Sans Arabic Medium.
  static const TextStyle arabic = TextStyle(
    fontFamily: _notoArabic,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Arabic Hero 36 / Noto Sans Arabic Medium —
  /// nom de prière dans le hero vidéo (SA-03).
  static const TextStyle arabicHero = TextStyle(
    fontFamily: _notoArabic,
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Geist Mono Regular — chiffres in-line (streaks, compteurs).
  static const TextStyle mono = TextStyle(
    fontFamily: _geistMono,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Micro 13 / Geist Regular — annotations fine print.
  static const TextStyle micro = TextStyle(
    fontFamily: _geist,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// NavLabel 10 / Geist Medium — libellé onglet bottom navigation bar (DS v1.5).
  static const TextStyle navLabel = TextStyle(
    fontFamily: _geist,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
}
