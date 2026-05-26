import 'package:equatable/equatable.dart';

/// Erreurs typées remontées par les use cases du système d'alertes
/// (ADR-018 §4.3). Permet à l'UI / au router de notifications de switcher
/// exhaustivement sur les causes sans interpréter d'exceptions natives.
///
/// Cf. ADR-018 §3.2 (actions figées), §3.3 (no-snooze prière + cap 2),
/// §10 Q-OPEN-C (cutoff minuit + late 24h).
sealed class OccurrenceFailure extends Equatable implements Exception {
  final String? message;

  const OccurrenceFailure._({this.message});

  /// L'occurrence est introuvable (id inconnu).
  const factory OccurrenceFailure.notFound({String? message}) =
      OccurrenceNotFoundFailure;

  /// Transition de status invalide (ex: valider une occurrence déjà `done`).
  /// Cf. ADR-018 §4.2 machine à états.
  const factory OccurrenceFailure.alreadyFinalized({String? message}) =
      OccurrenceAlreadyFinalizedFailure;

  /// La fenêtre de validation est dépassée (au-delà de J+1 pour les habit,
  /// au-delà du créneau pour les prières strictes). Cf. ADR-018 §10 Q-OPEN-C.
  const factory OccurrenceFailure.tooLateForCatchup({String? message}) =
      OccurrenceTooLateForCatchupFailure;

  /// Snooze tenté sur une occurrence de prière (BUG-004, CDC §13).
  const factory OccurrenceFailure.prayerSnoozeForbidden({String? message}) =
      OccurrencePrayerSnoozeForbiddenFailure;

  /// Snooze tenté alors que `snoozeCount == 2` (cap ADR-018 §3.3).
  const factory OccurrenceFailure.maxSnoozesReached({String? message}) =
      OccurrenceMaxSnoozesReachedFailure;

  /// Erreur infrastructure remontée par le repository.
  const factory OccurrenceFailure.repository({String? message}) =
      OccurrenceRepositoryFailure;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

class OccurrenceNotFoundFailure extends OccurrenceFailure {
  const OccurrenceNotFoundFailure({super.message}) : super._();
}

class OccurrenceAlreadyFinalizedFailure extends OccurrenceFailure {
  const OccurrenceAlreadyFinalizedFailure({super.message}) : super._();
}

class OccurrenceTooLateForCatchupFailure extends OccurrenceFailure {
  const OccurrenceTooLateForCatchupFailure({super.message}) : super._();
}

class OccurrencePrayerSnoozeForbiddenFailure extends OccurrenceFailure {
  const OccurrencePrayerSnoozeForbiddenFailure({super.message}) : super._();
}

class OccurrenceMaxSnoozesReachedFailure extends OccurrenceFailure {
  const OccurrenceMaxSnoozesReachedFailure({super.message}) : super._();
}

class OccurrenceRepositoryFailure extends OccurrenceFailure {
  const OccurrenceRepositoryFailure({super.message}) : super._();
}
