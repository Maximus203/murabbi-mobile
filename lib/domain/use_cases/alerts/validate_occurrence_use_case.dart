import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';

/// Valide une occurrence (action `done` utilisateur).
///
/// Règles métier (ADR-018 §4.3 + Q-OPEN-C §10) :
/// - Idempotence (BUG-003) : si l'occurrence est déjà `done`, retourne
///   immédiatement sans ré-écrire.
/// - `now <= scheduledAt - 60s` (anticipé) OU `now <= windowEndsAt` → `onTime`
/// - `now <= windowEndsAt + 24h`         → `late` (rattrapage J+1)
/// - `now >  windowEndsAt + 24h`         → throw `tooLateForCatchup`
///
/// La comparaison est faite en UTC — [windowEndsAt] est stocké en UTC
/// (ADR-018 §3.5). [Occurrence.deviceTimezone] sert aux appelants qui
/// recalculent [windowEndsAt] depuis le timezone device (BUG-004).
///
/// Idempotence : refuse de valider une occurrence déjà finalisée
/// (`missed` / `cancelled`). `dismissed` reste re-validable via
/// dashboard (ADR-018 §4.2).
class ValidateOccurrenceUseCase {
  final OccurrenceRepository _repository;

  const ValidateOccurrenceUseCase(this._repository);

  Future<Occurrence> call({
    required String occurrenceId,
    required ValidationSource source,
    DateTime? now,
  }) async {
    final occ = await _repository.findById(occurrenceId);
    if (occ == null) {
      throw OccurrenceFailure.notFound(
        message: 'Occurrence $occurrenceId introuvable',
      );
    }

    // ── Idempotence (BUG-003) ────────────────────────────────────────────────
    // Si l'occurrence est déjà `done`, retourne sans ré-écrire.
    if (occ.status == OccurrenceStatus.done) {
      return occ;
    }

    if (occ.status.isFinalized) {
      throw OccurrenceFailure.alreadyFinalized(
        message: 'Occurrence ${occ.id} déjà en status ${occ.status.name}',
      );
    }

    final at = now ?? DateTime.now().toUtc();
    final outcome = _resolveOutcome(occ, at);

    // On reconstruit l'entité plutôt que d'utiliser `copyWith` : ce dernier
    // utilise `??` et ne permet pas de remettre `nextFireAt` à `null`.
    // Forcer `nextFireAt = null` est requis pour empêcher le scheduler local
    // de re-fire la notif après validation d'une occurrence snoozée
    // (cf. PR #194 review P2 + ADR-018 §4.2).
    final updated = Occurrence(
      id: occ.id,
      source: occ.source,
      sourceId: occ.sourceId,
      userId: occ.userId,
      scheduledAt: occ.scheduledAt,
      windowEndsAt: occ.windowEndsAt,
      status: OccurrenceStatus.done,
      outcome: outcome,
      snoozeCount: occ.snoozeCount,
      firedAt: occ.firedAt,
      actedAt: at,
      validationSource: source,
      payloadJson: occ.payloadJson,
      deviceTimezone: occ.deviceTimezone,
      createdAt: occ.createdAt,
      updatedAt: at,
    );

    await _repository.save(updated);
    return updated;
  }

  OccurrenceOutcome _resolveOutcome(Occurrence occ, DateTime now) {
    // onTime : tap anticipé (≤ 60s avant scheduledAt) OU dans la grace
    // window. Cf. ADR-018 §4.3.
    // La comparaison est faite en UTC (BUG-004 : windowEndsAt déjà en UTC).
    final onTimeStart = occ.scheduledAt.toUtc().subtract(Occurrence.onTimeLead);
    final windowEnd = occ.windowEndsAt.toUtc();
    final utcNow = now.toUtc();
    if (!utcNow.isBefore(onTimeStart) && !utcNow.isAfter(windowEnd)) {
      return OccurrenceOutcome.onTime;
    }

    // late : rattrapage J+1 (Q-OPEN-C §10).
    final lateCutoff = windowEnd.add(Occurrence.lateCatchupGrace);
    if (!utcNow.isAfter(lateCutoff)) {
      return OccurrenceOutcome.late;
    }

    throw OccurrenceFailure.tooLateForCatchup(
      message:
          'Validation refusée : now=$now > windowEndsAt+24h=$lateCutoff '
          '(occ=${occ.id})',
    );
  }
}
