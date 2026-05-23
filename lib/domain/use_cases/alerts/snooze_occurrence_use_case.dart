import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';

/// Snooze une occurrence (action `later` utilisateur).
///
/// Règles métier (ADR-018 §3.3) :
/// - `source == prayer` → `prayerSnoozeForbidden` (BUG-004, CDC §13)
/// - `snoozeCount >= 2` → `maxSnoozesReached`
/// - sinon : `snoozeCount++`, `status=snoozed`,
///   `nextFireAt = now + 30min`. `scheduledAt` original ne bouge **pas**
///   (préserve le calcul `onTime`/`late` au moment de la validation).
class SnoozeOccurrenceUseCase {
  final OccurrenceRepository _repository;

  const SnoozeOccurrenceUseCase(this._repository);

  Future<Occurrence> call({required String occurrenceId, DateTime? now}) async {
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

    if (occ.source.isPrayer) {
      throw const OccurrenceFailure.prayerSnoozeForbidden(
        message: 'Snooze interdit sur prière (CDC §13, BUG-004)',
      );
    }

    if (occ.snoozeCount >= Occurrence.maxSnoozes) {
      throw OccurrenceFailure.maxSnoozesReached(
        message: 'Snooze max atteint (${Occurrence.maxSnoozes}) pour ${occ.id}',
      );
    }

    final at = now ?? DateTime.now().toUtc();
    final updated = occ.copyWith(
      snoozeCount: occ.snoozeCount + 1,
      status: OccurrenceStatus.snoozed,
      nextFireAt: at.add(Occurrence.snoozeDuration),
      updatedAt: at,
    );

    await _repository.save(updated);
    return updated;
  }
}
