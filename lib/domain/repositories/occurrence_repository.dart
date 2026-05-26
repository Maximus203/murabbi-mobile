import 'package:murabbi_mobile/domain/entities/habit_occurrence.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';

/// Contrat de persistance des occurrences (prières + habitudes).
///
/// Cette interface est intentionnellement large pour couvrir les deux
/// ensembles de use cases :
/// - **Alertes generiques (ADR-018 §4.2)** : [findById], [save],
///   [findOverdueActive], [saveAll] — utilisés par les use cases du système
///   d'alertes unifié (MOB-002, MOB-003).
/// - **Feed habitudes (MOB-007)** : [getTodayOccurrences],
///   [validateOccurrence], [snoozeOccurrence], [expireOverdueOccurrences] —
///   utilisés par les providers Riverpod du dashboard.
///
/// L'implémentation concrète (`OccurrenceRepositoryImpl`) les câble sur la
/// même table Supabase `occurrences` (cf. ADR-018 §3.1).
abstract interface class OccurrenceRepository {
  // -----------------------------------------------------------------------
  // API système d'alertes générique (MOB-002 / MOB-003)
  // -----------------------------------------------------------------------

  /// Retourne l'occurrence par [id] ou `null` si introuvable.
  Future<Occurrence?> findById(String id);

  /// Persiste une occurrence (upsert sur PK `id`).
  Future<void> save(Occurrence occurrence);

  /// Retourne les occurrences dont `windowEndsAt < now` et dont le [status]
  /// est encore actif (pending / fired / snoozed / acknowledged).
  ///
  /// Utilisé par [ExpireOverdueOccurrencesUseCase] pour le batch d'expiration.
  Future<List<Occurrence>> findOverdueActive(DateTime now);

  /// Retourne toutes les occurrences en attente (pending ou snoozed) pour
  /// un habit donné. Utilisé par `cancelAllForHabit` (BUG-002).
  Future<List<Occurrence>> findPendingForHabit(String habitId);

  /// Retourne toutes les occurrences actives dont `windowEndsAt` est antérieur
  /// à [now] (tous types, tous utilisateurs).
  ///
  /// Alias sémantique de [findOverdueActive] — utilisé par
  /// `MarkMissedOccurrencesUseCase`.
  Future<List<Occurrence>> findExpiredBefore(DateTime now);

  /// Persiste une liste d'occurrences en une transaction (utilisé par le batch
  /// d'expiration). L'implémentation doit être atomique.
  Future<void> saveAll(List<Occurrence> occurrences);

  /// Supprime les occurrences archivées (done/dismissed/missed/cancelled)
  /// antérieures à [before] (garbage collection — cf. ADR-018 §5.5).
  Future<void> deleteArchivedBefore(DateTime before);

  // -----------------------------------------------------------------------
  // API feed habitudes (MOB-007)
  // -----------------------------------------------------------------------

  /// Retourne toutes les occurrences dont [HabitOccurrence.scheduledAt]
  /// tombe dans la journée locale courante.
  Future<List<HabitOccurrence>> getTodayOccurrences();

  /// Valide une occurrence (action `done`).
  ///
  /// Met à jour [HabitOccurrence.status] → [OccurrenceStatus.done]
  /// et horodate [HabitOccurrence.actedAt].
  Future<void> validateOccurrence({
    required String occurrenceId,
    required String userId,
  });

  /// Snooze une occurrence (+30 min, max 2 reports).
  ///
  /// Met à jour [HabitOccurrence.status] → [OccurrenceStatus.snoozed],
  /// incrémente [HabitOccurrence.snoozeCount], pose [HabitOccurrence.snoozedUntil].
  Future<void> snoozeOccurrence({
    required String occurrenceId,
    required String userId,
  });

  /// Marque toutes les occurrences dépassées (windowEndsAt < now)
  /// en [OccurrenceStatus.missed]. Retourne le nombre d'occurrences expirées.
  Future<int> expireOverdueOccurrences();
}
