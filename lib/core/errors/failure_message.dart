import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/errors/collection_failure.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';

/// Mapping centralisé `Failure → message FR canonique` (#201, M9).
///
/// Source de vérité unique pour les libellés d'erreur visibles dans l'UI.
/// Chaque branche `switch` est **exhaustive** sur la sealed class associée
/// — le compilateur détecte toute nouvelle variante ajoutée à un `Failure`
/// (cf. coordination M3 : ajout futur `unauthorized()` doit faire échouer
/// la compilation pour forcer le mapping).
///
/// Usage côté UI :
/// ```dart
/// Text(FailureMessage.from(failure))
/// // ou directement via le widget partagé :
/// AppErrorText(failure)
/// ```
class FailureMessage {
  const FailureMessage._();

  /// Message FR à afficher pour `failure`. Tolère `Object` pour absorber
  /// les `state.error` non typés de Riverpod. Toute valeur qui n'est pas
  /// une [Failure] connue tombe sur un libellé générique.
  static String from(Object failure) => switch (failure) {
    AuthFailure f => _fromAuth(f),
    ScoreFailure f => _fromScore(f),
    HabitFailure f => _fromHabit(f),
    CollectionFailure f => _fromCollection(f),
    PrayerFailure f => _fromPrayer(f),
    OccurrenceFailure f => _fromOccurrence(f),
    _ => _fallback,
  };

  static const String _fallback = 'Une erreur inattendue est survenue.';

  static String _fromAuth(AuthFailure f) => switch (f) {
    // "email not confirmed" → message distinct qui invite à valider l'inbox.
    InvalidCredentialsFailure(message: final msg)
        when msg != null && msg.toLowerCase().contains('email not confirmed') =>
      'Confirmez votre adresse email avant de vous connecter.',
    InvalidCredentialsFailure() => 'Email ou mot de passe incorrect.',
    EmailAlreadyInUseFailure() => 'Cet email est déjà utilisé.',
    WeakPasswordFailure() => 'Mot de passe trop faible (8 caractères minimum).',
    NetworkFailure() => 'Connexion impossible — vérifie ta connexion.',
    AccountDeletedFailure() =>
      'Ce compte a été supprimé. Contacte le support pour le restaurer.',
    UnknownAuthFailure() => 'Erreur inattendue. Réessaie dans un instant.',
  };

  static String _fromScore(ScoreFailure f) => switch (f) {
    ScoreNetworkFailure() =>
      'Impossible de charger le score. Vérifie ta connexion.',
    ScoreNotFoundFailure() => 'Score introuvable.',
    ScoreDatabaseFailure() => 'Erreur lors de la récupération du score.',
    ScoreUnknownFailure() => _fallback,
  };

  static String _fromHabit(HabitFailure f) => switch (f) {
    HabitFutureLogNotAllowedFailure() =>
      'Impossible de valider une habitude dans le futur.',
    HabitBackdateTooOldFailure() =>
      'Cette date est trop ancienne pour être validée (limite 8 jours).',
    HabitDatabaseFailure() => "Erreur lors de la mise à jour de l'habitude.",
    HabitNetworkFailure() => 'Connexion impossible — vérifie ta connexion.',
    HabitUnauthorizedFailure() => 'Action non autorisée. Reconnecte-toi.',
  };

  static String _fromCollection(CollectionFailure f) => switch (f) {
    CollectionNetworkFailure() =>
      'Impossible de charger les collections. Vérifie ta connexion.',
    CollectionDatabaseFailure() =>
      'Erreur lors de la récupération des collections.',
    CollectionNotFoundFailure() => 'Collection introuvable.',
    CollectionUnknownFailure() => _fallback,
    CollectionUnauthorizedFailure() => 'Action non autorisée. Reconnecte-toi.',
  };

  static String _fromPrayer(PrayerFailure f) => switch (f) {
    PrayerNetworkFailure() => 'Connexion impossible — vérifie ta connexion.',
    PrayerDatabaseFailure() => 'Erreur lors de la récupération des prières.',
    PrayerMalformedRowFailure() =>
      'Données de prière invalides. Contacte le support.',
    UnknownPrayerStatusFailure() =>
      'Statut de prière inconnu. Contacte le support.',
    PrayerSettingsNotConfiguredFailure() =>
      'Configure tes réglages de prière pour commencer.',
    UnknownPrayerFailure() => _fallback,
  };

  static String _fromOccurrence(OccurrenceFailure f) => switch (f) {
    OccurrenceNotFoundFailure() => 'Cette occurrence est introuvable.',
    OccurrenceAlreadyFinalizedFailure() =>
      'Cette occurrence a déjà été traitée.',
    OccurrenceTooLateForCatchupFailure() =>
      'Trop tard pour valider cette occurrence.',
    OccurrencePrayerSnoozeForbiddenFailure() =>
      'Les prières ne peuvent pas être reportées.',
    OccurrenceMaxSnoozesReachedFailure() =>
      'Nombre maximum de reports atteint.',
    OccurrenceRepositoryFailure() =>
      'Une erreur est survenue. Réessaie dans un instant.',
  };
}
