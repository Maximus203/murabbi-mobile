import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

/// Typographie Murabbi — Geist + Geist Mono + Noto Sans Arabic uniquement (P-3).
///
/// Source de vérité : DS sheet § Typographie.
///
/// **Note implémentation** : Geist et Geist Mono ne sont actuellement pas
/// disponibles dans `google_fonts` 6.3.x. Cette classe expose les `TextStyle`
/// avec leurs `fontFamily` Murabbi ; la résolution effective des polices se
/// fait via `pubspec.yaml > flutter.fonts` une fois les fichiers TTF bundlés
/// (Phase 2 — actifs Geist + Noto Sans Arabic à fournir par le PO). Tant que
/// les TTFs ne sont pas en place, Flutter retombe sur la police système — les
/// tailles, poids, et tracking restent honorés.
class AppTypography {
  AppTypography._();

  /// Famille principale — corps de texte, titres latins.
  static const String _geist = 'Geist';

  /// Famille mono — chiffres scoring, timer, captions Geist Mono.
  static const String _geistMono = 'Geist Mono';

  /// Famille arabe — noms de prières, dhikr.
  static const String _notoArabic = 'Noto Sans Arabic';

  /// Display 42 / Geist Mono Medium / -1px tracking.
  static const TextStyle display = TextStyle(
    fontFamily: _geistMono,
    fontSize: 42,
    fontWeight: FontWeight.w500,
    letterSpacing: -1,
    color: AppColors.textPrimary,
  );

  /// H1 26 / Geist SemiBold / -0.3px — titre d'écran.
  static const TextStyle h1 = TextStyle(
    fontFamily: _geist,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// H2 18 / Geist SemiBold — sous-titre de section.
  static const TextStyle h2 = TextStyle(
    fontFamily: _geist,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// H3 15 / Geist Medium — titre de carte.
  static const TextStyle h3 = TextStyle(
    fontFamily: _geist,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Body 14 / Geist Regular — texte courant.
  static const TextStyle body = TextStyle(
    fontFamily: _geist,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Label 11 / Geist Medium — UPPERCASE attendu côté usage.
  static const TextStyle label = TextStyle(
    fontFamily: _geist,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  /// Caption 11 / Geist Regular.
  static const TextStyle caption = TextStyle(
    fontFamily: _geist,
    fontSize: 11,
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

  /// Geist Mono Regular — chiffres in-line (streaks, compteurs).
  static const TextStyle mono = TextStyle(
    fontFamily: _geistMono,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
}
