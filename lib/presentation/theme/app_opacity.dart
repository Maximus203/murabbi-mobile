/// Tokens d'opacité Murabbi — couche de transparence sémantique.
///
/// Usage : `.withValues(alpha: AppOpacity.xxx)`.
///
/// Ces tokens couvrent deux familles de cas :
/// - États sélectionnés sur fond coloré ([tint]).
/// - Superpositions texte/icône sur fond vidéo ou gradient sombre
///   ([overlayMedium], [overlayStrong], [overlayEmphasis]).
///
/// Toutes les autres alpha (0.08, 0.12, 0.16, 0.25, 0.30…) sont des teintures
/// propres à un composant donné et restent locales à ce composant.
/// Seules les valeurs qui traversent plusieurs écrans indépendants méritent un token.
class AppOpacity {
  AppOpacity._();

  /// 0.15 — fond teinté état sélectionné (ex. AppChip actif, badge).
  static const double tint = 0.15;

  /// 0.55 — superposition intermédiaire sur vidéo/média (gradient dégradé).
  static const double overlayMedium = 0.55;

  /// 0.70 — label/caption sur fond sombre (lisibilité overlay vidéo).
  static const double overlayStrong = 0.70;

  /// 0.85 — corps de texte sur fond sombre (lisibilité overlay vidéo).
  static const double overlayEmphasis = 0.85;
}
