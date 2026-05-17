import 'package:flutter/material.dart';

/// Tokens couleurs Murabbi — palette terreuse v3.
///
/// **Source de vérité** : `docs/wireframes/bundle/design-system-sheet.jsx`.
/// **Règle P-2** : aucune valeur hex ne doit apparaître hors de ce fichier.
/// Si un nouveau besoin émerge, ajouter ici avec un nom et justifier dans
/// le commentaire de bloc.
class AppColors {
  AppColors._();

  // -- Backgrounds & texte ----------------------------------------------------
  /// Fond principal (sable clair) — surface dominante.
  static const Color bgPrimary = Color(0xFFF5F2ED);

  /// Surface élevée — cartes, inputs au repos, fond de modaux.
  static const Color bgSurface = Color(0xFFFDFBF8);

  /// Surface d'input "pressée" / état désactivé doux.
  static const Color bgInput = Color(0xFFEDE9E2);

  /// Texte principal — anthracite-brun.
  static const Color textPrimary = Color(0xFF1C1A16);

  /// Texte secondaire — info de support.
  static const Color textSecondary = Color(0xFF6B6155);

  /// Texte tertiaire — placeholders, hints.
  static const Color textTertiary = Color(0xFFA89880);

  // -- Accent ocre & sémantiques ---------------------------------------------
  /// Accent ocre — un seul CTA primaire par écran (P-6).
  static const Color accent = Color(0xFF8B6F47);

  /// État hover/pressed du CTA primaire.
  static const Color accentHover = Color(0xFF7A6240);

  /// Statut "succès" — vert sauge.
  static const Color success = Color(0xFF6B8C6B);

  /// Statut "warning" — terracotta.
  static const Color warning = Color(0xFF9B5E3C);

  /// Statut "danger" / erreur — rouge brique.
  static const Color danger = Color(0xFF8C3D3D);

  /// Bordure emphase — `rgba(28,26,22,0.16)` du DS sheet.
  /// Convertie en `0x29 1C1A16` côté Flutter (0.16 × 255 ≈ 41 = 0x29).
  static const Color borderEmphasis = Color(0x291C1A16);

  /// Bordure par défaut thin — 0.5px (P-5), opacité plus douce.
  /// Cf. DS sheet variable `--border-default`.
  static const Color borderDefault = Color(0x141C1A16); // ~0.08 alpha

  // -- Catégories (DS sheet § Catégories) ------------------------------------
  /// Religion — identique à `accent` ocre, légitime du point de vue DS.
  static const Color categoryReligion = Color(0xFF8B6F47);
  static const Color categorySport = Color(0xFF6B8C6B);
  static const Color categorySante = Color(0xFF5C7A8C);
  static const Color categoryMental = Color(0xFF7A6B8C);
  static const Color categorySocial = Color(0xFF9B7A4A);

  /// Couleurs catégorie additionnelles (issue #150 — HB-04 ColorPickerGrid).
  /// Complètent la palette terreuse à 9 teintes pour le sélecteur de couleur
  /// de catégorie utilisateur. Tons cohérents avec la palette v3.
  static const Color categoryEtudes = Color(0xFF8C6B5C);
  static const Color categoryFamille = Color(0xFFA88C5C);
  static const Color categoryFinance = Color(0xFF5C8C7A);
  static const Color categoryCreatif = Color(0xFF8C5C6B);

  /// Palette complète des couleurs assignables à une catégorie (HB-04).
  /// Ordre figé — utilisé tel quel par `ColorPickerGrid` (9 cases).
  static const List<Color> categoryPalette = [
    categoryReligion,
    categorySport,
    categorySante,
    categoryMental,
    categorySocial,
    categoryEtudes,
    categoryFamille,
    categoryFinance,
    categoryCreatif,
  ];

  // -- Utilitaires -----------------------------------------------------------
  /// Transparent pur — utilisé pour les variantes ghost/link de AppButton (P-2).
  /// Centralise l'usage de `Colors.transparent` pour respecter la règle P-2 :
  /// aucune valeur couleur hors de AppColors.
  static const Color transparent = Colors.transparent;
}
