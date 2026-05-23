import 'package:murabbi_mobile/domain/entities/occurrence.dart';

/// Interface du repository d'occurrences (ADR-018 §4.2).
///
/// L'implémentation concrète (Drift local, optionnellement Supabase) est
/// livrée par MOB-007. Les use cases du système d'alertes consomment
/// uniquement cette interface.
abstract class OccurrenceRepository {
  /// Retourne l'occurrence par id ou `null` si introuvable.
  Future<Occurrence?> findById(String id);

  /// Persiste une occurrence (upsert sur PK `id`).
  Future<void> save(Occurrence occurrence);

  /// Retourne les occurrences dont `windowEndsAt < now` et dont le `status`
  /// est encore actif (pending / fired / snoozed / acknowledged).
  ///
  /// Utilisé par `ExpireOverdueOccurrencesUseCase` pour le batch d'expiration.
  Future<List<Occurrence>> findOverdueActive(DateTime now);

  /// Persiste une liste d'occurrences en une transaction (utilisé par le batch
  /// d'expiration). Implémentation doit être atomique.
  Future<void> saveAll(List<Occurrence> occurrences);
}
