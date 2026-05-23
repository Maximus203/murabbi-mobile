import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';

/// Expire en batch les occurrences dont `windowEndsAt < now` et qui sont
/// encore dans un état actif (pending / fired / snoozed / acknowledged).
///
/// Cf. ADR-018 §4.3 (MarkMissedOccurrencesUseCase) + §10 Q-OPEN-B (cutoff
/// strict minuit local, exécuté à 00:00:05 local).
///
/// Le filtrage SQL (statuts actifs + windowEndsAt < now) est délégué au
/// repository (`findOverdueActive`) — le use case ne re-filtre pas.
/// Retourne le nombre d'occurrences expirées.
class ExpireOverdueOccurrencesUseCase {
  final OccurrenceRepository _repository;

  const ExpireOverdueOccurrencesUseCase(this._repository);

  Future<int> call({DateTime? now}) async {
    final at = now ?? DateTime.now().toUtc();
    final overdue = await _repository.findOverdueActive(at);

    if (overdue.isEmpty) {
      return 0;
    }

    final expired = overdue
        .map(
          (o) => o.copyWith(
            status: OccurrenceStatus.missed,
            outcome: OccurrenceOutcome.missed,
            validationSource: ValidationSource.autoExpire,
            actedAt: at,
            updatedAt: at,
          ),
        )
        .toList(growable: false);

    await _repository.saveAll(expired);
    return expired.length;
  }
}
