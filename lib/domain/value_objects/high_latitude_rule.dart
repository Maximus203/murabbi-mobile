/// Règle de calcul Fajr / Isha aux hautes latitudes (>~48°), cf. ADR-013
/// §Limites.
///
/// Aux latitudes élevées, certaines nuits Fajr et Isha n'existent pas
/// astronomiquement (le soleil ne descend jamais sous les angles requis).
/// `adhan_dart` expose 3 stratégies équivalentes à la spec praytimes.org.
enum HighLatitudeRule {
  /// Middle of the Night — Fajr commence à mi-chemin entre Maghrib et le
  /// lever du soleil (le plus permissif).
  middleOfTheNight,

  /// Seventh of the Night — Fajr commence au dernier septième de la nuit
  /// (recommandation Moonsighting Committee >55°, défaut robuste).
  seventhOfTheNight,

  /// Twilight Angle — applique l'angle de la méthode même quand
  /// astronomiquement la nuit ne descend pas si bas (le plus strict, peut
  /// produire des horaires extrêmes en juin Oslo).
  twilightAngle,
}
