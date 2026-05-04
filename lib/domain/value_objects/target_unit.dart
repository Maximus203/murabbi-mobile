/// Unités d'objectif chiffré pour une habitude (spec v1.5 § 3.4).
///
/// Le mapping vers le SQL est plat (`target_unit varchar(20)` côté Supabase),
/// la conversion `String ↔ TargetUnit` est confinée au repository (cf. ADR-008).
enum TargetUnit {
  minutes,
  hours,
  pages,
  glasses,
  reps,
  sets,
  km,
  meters,
  steps,

  /// Texte libre porté par `HabitTarget.value.customLabel`.
  custom;

  /// Vrai uniquement pour `minutes` et `hours` — seules unités compatibles
  /// avec le timer in-app (cf. spec v1.5 § 3.5).
  bool get isTimeBased => this == TargetUnit.minutes || this == TargetUnit.hours;

  static TargetUnit parse(String raw) {
    for (final unit in TargetUnit.values) {
      if (unit.name == raw) return unit;
    }
    throw ArgumentError.value(raw, 'raw', 'Unknown TargetUnit');
  }
}
