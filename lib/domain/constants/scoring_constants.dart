/// Barèmes de scoring Murabbi — source de vérité unique (issue #6, Phase 5).
///
/// Règle non négociable : aucun magic number dans les use cases de scoring.
/// Toute constante de points ou de fenêtre temporelle vit ici.
///
/// Barèmes verrouillés :
/// - Prière : à l'heure +3 / en retard ou rattrapée +1 / manquée 0.
/// - Habitude : faite ⇒ points de l'habitude / en retard +1 / manquée 0.
/// - Score hebdomadaire : somme des points sur une fenêtre de 7 jours.
class ScoringConstants {
  const ScoringConstants._();

  /// Points d'une prière accomplie à l'heure (`PrayerStatus.onTime`).
  static const int prayerOnTimePoints = 3;

  /// Points d'une prière en retard ou rattrapée (`late` / `makeup`).
  static const int prayerLatePoints = 1;

  /// Points d'une prière manquée ou non encore renseignée (`missed` /
  /// `pending`).
  static const int prayerMissedPoints = 0;

  /// Points d'une habitude validée en retard (`HabitLogStatus.late`).
  ///
  /// Spec v1.5 § 3.2 : le statut « en retard » rapporte un point fixe,
  /// indépendamment du barème propre de l'habitude.
  static const int habitLatePoints = 1;

  /// Points d'une habitude manquée (`HabitLogStatus.missed`).
  static const int habitMissedPoints = 0;

  /// Longueur de la fenêtre du score hebdomadaire (en jours).
  static const int weekLengthDays = 7;
}
