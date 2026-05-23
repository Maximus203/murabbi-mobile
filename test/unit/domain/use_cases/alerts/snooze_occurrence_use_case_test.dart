// Tests RED → GREEN — SnoozeOccurrenceUseCase (MOB-003, issue #171).
// Cf. ADR-018 §3.3 (snooze 2x max +30min, jamais sur prière, BUG-004).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/alerts/snooze_occurrence_use_case.dart';

class _MockOccurrenceRepository extends Mock implements OccurrenceRepository {}

void main() {
  late _MockOccurrenceRepository repo;
  late SnoozeOccurrenceUseCase useCase;

  final scheduledAt = DateTime.utc(2026, 5, 23, 8);
  final windowEndsAt = DateTime.utc(2026, 5, 23, 23, 59, 59);

  Occurrence makeHabit({int snoozeCount = 0}) {
    final t = DateTime.utc(2026, 5, 23, 7);
    return Occurrence(
      id: 'occ-001',
      source: OccurrenceSource.habit,
      sourceId: 'habit-001',
      userId: 'user-001',
      scheduledAt: scheduledAt,
      windowEndsAt: windowEndsAt,
      status: OccurrenceStatus.fired,
      snoozeCount: snoozeCount,
      createdAt: t,
      updatedAt: t,
    );
  }

  Occurrence makePrayer() {
    final t = DateTime.utc(2026, 5, 23, 7);
    return Occurrence(
      id: 'occ-prayer-001',
      source: OccurrenceSource.prayer,
      sourceId: 'dhuhr',
      userId: 'user-001',
      scheduledAt: scheduledAt,
      windowEndsAt: DateTime.utc(2026, 5, 23, 15),
      status: OccurrenceStatus.fired,
      snoozeCount: 0,
      createdAt: t,
      updatedAt: t,
    );
  }

  setUpAll(() {
    registerFallbackValue(
      Occurrence(
        id: 'fallback',
        source: OccurrenceSource.habit,
        sourceId: 'fallback',
        userId: 'fallback',
        scheduledAt: DateTime.utc(2026),
        windowEndsAt: DateTime.utc(2026),
        status: OccurrenceStatus.pending,
        snoozeCount: 0,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    repo = _MockOccurrenceRepository();
    useCase = SnoozeOccurrenceUseCase(repo);
    when(() => repo.save(any())).thenAnswer((_) async {});
  });

  group('SnoozeOccurrenceUseCase — happy path', () {
    test('1er snooze : snoozeCount 0→1, status=snoozed, nextFireAt=now+30min',
        () async {
      when(
        () => repo.findById('occ-001'),
      ).thenAnswer((_) async => makeHabit());

      final now = DateTime.utc(2026, 5, 23, 8, 5);
      final result = await useCase.call(occurrenceId: 'occ-001', now: now);

      expect(result.snoozeCount, 1);
      expect(result.status, OccurrenceStatus.snoozed);
      expect(result.nextFireAt, now.add(Occurrence.snoozeDuration));
      expect(
        result.scheduledAt,
        scheduledAt,
        reason: 'scheduledAt original ne doit pas bouger (calc onTime/late)',
      );
    });

    test('2ème snooze : snoozeCount 1→2 autorisé', () async {
      when(() => repo.findById('occ-001')).thenAnswer(
        (_) async => makeHabit(snoozeCount: 1),
      );

      final now = DateTime.utc(2026, 5, 23, 8, 40);
      final result = await useCase.call(occurrenceId: 'occ-001', now: now);

      expect(result.snoozeCount, 2);
      expect(result.status, OccurrenceStatus.snoozed);
    });
  });

  group('SnoozeOccurrenceUseCase — règles métier', () {
    test('3ème snooze (count déjà à 2) → MaxSnoozesReachedFailure', () async {
      when(() => repo.findById('occ-001')).thenAnswer(
        (_) async => makeHabit(snoozeCount: 2),
      );

      expect(
        () => useCase.call(
          occurrenceId: 'occ-001',
          now: DateTime.utc(2026, 5, 23, 9),
        ),
        throwsA(isA<OccurrenceMaxSnoozesReachedFailure>()),
      );
    });

    test('snooze sur prière → PrayerSnoozeForbiddenFailure (BUG-004)',
        () async {
      when(
        () => repo.findById('occ-prayer-001'),
      ).thenAnswer((_) async => makePrayer());

      expect(
        () => useCase.call(
          occurrenceId: 'occ-prayer-001',
          now: DateTime.utc(2026, 5, 23, 8, 5),
        ),
        throwsA(isA<OccurrencePrayerSnoozeForbiddenFailure>()),
      );
    });

    test('occurrence introuvable → NotFoundFailure', () async {
      when(() => repo.findById('inconnu')).thenAnswer((_) async => null);

      expect(
        () => useCase.call(
          occurrenceId: 'inconnu',
          now: DateTime.utc(2026, 5, 23, 8, 5),
        ),
        throwsA(isA<OccurrenceNotFoundFailure>()),
      );
    });

    test('occurrence déjà finalisée → AlreadyFinalizedFailure', () async {
      when(() => repo.findById('occ-001')).thenAnswer(
        (_) async => makeHabit().copyWith(status: OccurrenceStatus.done),
      );

      expect(
        () => useCase.call(
          occurrenceId: 'occ-001',
          now: DateTime.utc(2026, 5, 23, 8, 5),
        ),
        throwsA(isA<OccurrenceAlreadyFinalizedFailure>()),
      );
    });
  });

  group('SnoozeOccurrenceUseCase — persistance', () {
    test('save() est appelé avec la version mise à jour', () async {
      when(
        () => repo.findById('occ-001'),
      ).thenAnswer((_) async => makeHabit());

      final now = DateTime.utc(2026, 5, 23, 8, 5);
      await useCase.call(occurrenceId: 'occ-001', now: now);

      final saved =
          verify(() => repo.save(captureAny())).captured.first as Occurrence;
      expect(saved.snoozeCount, 1);
      expect(saved.nextFireAt, now.add(Occurrence.snoozeDuration));
      expect(saved.updatedAt, now);
    });

    test('utilise DateTime.now() si paramètre `now` non fourni', () async {
      when(
        () => repo.findById('occ-001'),
      ).thenAnswer((_) async => makeHabit());

      await useCase.call(occurrenceId: 'occ-001');

      verify(() => repo.save(any())).called(1);
    });
  });
}
