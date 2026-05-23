import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';

/// Valide une occurrence (action `done` utilisateur).
///
/// Règles métier (ADR-018 §4.3 + Q-OPEN-C §10) :
/// - `now <= scheduledAt - 60s` (anticipé) → `onTime`
/// - `now <= windowEndsAt`               → `onTime`
/// - `now <= windowEndsAt + 24h`         → `late` (rattrapage J+1)
/// - `now >  windowEndsAt + 24h`         → throw `tooLateForCatchup`
///
/// Idempotence : refuse de valider une occurrence déjà finalisée
/// (`done` / `missed` / `cancelled`). `dismissed` reste re-validable via
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

    if (occ.status.isFinalized) {
      throw OccurrenceFailure.alreadyFinalized(
        message: 'Occurrence ${occ.id} déjà en status ${occ.status.name}',
      );
    }

    final at = now ?? DateTime.now().toUtc();
    final outcome = _resolveOutcome(occ, at);

    final updated = occ.copyWith(
      status: OccurrenceStatus.done,
      outcome: outcome,
      validationSource: source,
      actedAt: at,
      updatedAt: at,
    );

    await _repository.save(updated);
    return updated;
  }

  OccurrenceOutcome _resolveOutcome(Occurrence occ, DateTime now) {
    // onTime : tap anticipé (≤ 60s avant scheduledAt) OU dans la grace
    // window. Cf. ADR-018 §4.3.
    final onTimeStart = occ.scheduledAt.subtract(Occurrence.onTimeLead);
    if (!now.isBefore(onTimeStart) && !now.isAfter(occ.windowEndsAt)) {
      return OccurrenceOutcome.onTime;
    }

    // late : rattrapage J+1 (Q-OPEN-C §10).
    final lateCutoff = occ.windowEndsAt.add(Occurrence.lateCatchupGrace);
    if (!now.isAfter(lateCutoff)) {
      return OccurrenceOutcome.late;
    }

    throw OccurrenceFailure.tooLateForCatchup(
      message:
          'Validation refusée : now=$now > windowEndsAt+24h=$lateCutoff '
          '(occ=${occ.id})',
    );
  }
}
