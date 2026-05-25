// Tests RED → GREEN — ExpireOverdueOccurrencesUseCase (MOB-003, issue #171).
// Cf. ADR-018 §4.3 (MarkMissedOccurrencesUseCase), §10 Q-OPEN-B (cutoff
// strict minuit local).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/alerts/expire_overdue_use_case.dart';

class _MockOccurrenceRepository extends Mock implements OccurrenceRepository {}

void main() {
  late _MockOccurrenceRepository repo;
  late ExpireOverdueOccurrencesUseCase useCase;

  Occurrence makeOcc({
    required String id,
    required OccurrenceStatus status,
    required DateTime windowEndsAt,
    int snoozeCount = 0,
  }) {
    final t = DateTime.utc(2026, 5, 23);
    return Occurrence(
      id: id,
      source: OccurrenceSource.habit,
      sourceId: 'habit-001',
      userId: 'user-001',
      scheduledAt: t,
      windowEndsAt: windowEndsAt,
      status: status,
      snoozeCount: snoozeCount,
      createdAt: t,
      updatedAt: t,
    );
  }

  setUpAll(() {
    registerFallbackValue(<Occurrence>[]);
  });

  setUp(() {
    repo = _MockOccurrenceRepository();
    useCase = ExpireOverdueOccurrencesUseCase(repo);
    when(() => repo.saveAll(any())).thenAnswer((_) async {});
  });

  group('ExpireOverdueOccurrencesUseCase —', () {
    test(
      'passe les occurrences overdue actives en missed + outcome=missed',
      () async {
        final yesterdayEnd = DateTime.utc(2026, 5, 22, 23, 59, 59);
        final overdue = [
          makeOcc(
            id: 'a',
            status: OccurrenceStatus.pending,
            windowEndsAt: yesterdayEnd,
          ),
          makeOcc(
            id: 'b',
            status: OccurrenceStatus.fired,
            windowEndsAt: yesterdayEnd,
          ),
          makeOcc(
            id: 'c',
            status: OccurrenceStatus.snoozed,
            windowEndsAt: yesterdayEnd,
            snoozeCount: 1,
          ),
        ];
        final now = DateTime.utc(2026, 5, 23, 0, 5);

        when(
          () => repo.findOverdueActive(now),
        ).thenAnswer((_) async => overdue);

        final count = await useCase.call(now: now);

        expect(count, 3);
        final saved =
            verify(() => repo.saveAll(captureAny())).captured.first
                as List<Occurrence>;
        expect(saved, hasLength(3));
        for (final occ in saved) {
          expect(occ.status, OccurrenceStatus.missed);
          expect(occ.outcome, OccurrenceOutcome.missed);
          expect(occ.validationSource, ValidationSource.autoExpire);
          expect(occ.actedAt, now);
        }
      },
    );

    test('retourne 0 si aucune occurrence overdue', () async {
      final now = DateTime.utc(2026, 5, 23, 0, 5);
      when(() => repo.findOverdueActive(now)).thenAnswer((_) async => []);

      final count = await useCase.call(now: now);

      expect(count, 0);
      verifyNever(() => repo.saveAll(any()));
    });

    test(
      'le filtre overdue est délégué au repository (use case ne refiltre pas)',
      () async {
        // Le repository ne renvoie que les rows pertinentes — le use case
        // les expire toutes sans re-filtrer (contrat ADR-018 §4.2).
        final yesterdayEnd = DateTime.utc(2026, 5, 22, 23, 59, 59);
        final now = DateTime.utc(2026, 5, 23, 0, 5);

        when(() => repo.findOverdueActive(now)).thenAnswer(
          (_) async => [
            makeOcc(
              id: 'x',
              status: OccurrenceStatus.acknowledged,
              windowEndsAt: yesterdayEnd,
            ),
          ],
        );

        final count = await useCase.call(now: now);
        expect(count, 1);
      },
    );

    test('utilise DateTime.now() si paramètre `now` non fourni', () async {
      when(() => repo.findOverdueActive(any())).thenAnswer((_) async => []);

      await useCase.call();

      verify(() => repo.findOverdueActive(any())).called(1);
    });
  });
}
