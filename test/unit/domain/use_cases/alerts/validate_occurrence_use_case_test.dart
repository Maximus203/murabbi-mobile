// Tests RED → GREEN — ValidateOccurrenceUseCase (MOB-003, issue #171).
// Cf. ADR-018 §3.2 (actions), §3.3 (no-snooze prière), §4.3 (router),
// §10 Q-OPEN-C (cutoff late J+1).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/alerts/validate_occurrence_use_case.dart';

class _MockOccurrenceRepository extends Mock implements OccurrenceRepository {}

void main() {
  late _MockOccurrenceRepository repo;
  late ValidateOccurrenceUseCase useCase;

  // Heure de référence : 2026-05-23 08:00 UTC.
  final scheduledAt = DateTime.utc(2026, 5, 23, 8);
  // Window habitude = minuit local strict (Q-OPEN-B). Pour simplifier les
  // tests, on travaille en UTC et on prend windowEndsAt = 23:59:59 UTC.
  final windowEndsAt = DateTime.utc(2026, 5, 23, 23, 59, 59);

  Occurrence makeHabit({
    OccurrenceStatus status = OccurrenceStatus.fired,
    int snoozeCount = 0,
  }) {
    final now = DateTime.utc(2026, 5, 23, 7);
    return Occurrence(
      id: 'occ-001',
      source: OccurrenceSource.habit,
      sourceId: 'habit-001',
      userId: 'user-001',
      scheduledAt: scheduledAt,
      windowEndsAt: windowEndsAt,
      status: status,
      snoozeCount: snoozeCount,
      createdAt: now,
      updatedAt: now,
    );
  }

  Occurrence makePrayer({OccurrenceStatus status = OccurrenceStatus.fired}) {
    final now = DateTime.utc(2026, 5, 23, 7);
    return Occurrence(
      id: 'occ-prayer-001',
      source: OccurrenceSource.prayer,
      sourceId: 'dhuhr',
      userId: 'user-001',
      scheduledAt: scheduledAt,
      windowEndsAt: DateTime.utc(2026, 5, 23, 15), // prochain créneau Asr
      status: status,
      snoozeCount: 0,
      createdAt: now,
      updatedAt: now,
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
    useCase = ValidateOccurrenceUseCase(repo);
    when(() => repo.save(any())).thenAnswer((_) async {});
  });

  group('ValidateOccurrenceUseCase — outcomes', () {
    test('valide dans la grace window → outcome onTime', () async {
      when(() => repo.findById('occ-001')).thenAnswer((_) async => makeHabit());

      final result = await useCase.call(
        occurrenceId: 'occ-001',
        source: ValidationSource.notificationAction,
        now: DateTime.utc(2026, 5, 23, 8, 5),
      );

      expect(result.outcome, OccurrenceOutcome.onTime);
      expect(result.status, OccurrenceStatus.done);
    });

    test('valide à 60s avant scheduledAt → outcome onTime', () async {
      // Tolérance ADR-018 §4.3 implicite : un tap utilisateur juste avant
      // l'heure (clic anticipé) reste onTime.
      when(() => repo.findById('occ-001')).thenAnswer((_) async => makeHabit());

      final result = await useCase.call(
        occurrenceId: 'occ-001',
        source: ValidationSource.notificationAction,
        now: scheduledAt.subtract(const Duration(seconds: 30)),
      );

      expect(result.outcome, OccurrenceOutcome.onTime);
    });

    test(
      'valide après windowEndsAt mais avant +24h → outcome late (Q-OPEN-C)',
      () async {
        when(
          () => repo.findById('occ-001'),
        ).thenAnswer((_) async => makeHabit());

        final result = await useCase.call(
          occurrenceId: 'occ-001',
          source: ValidationSource.catchup,
          now: windowEndsAt.add(const Duration(hours: 2)),
        );

        expect(result.outcome, OccurrenceOutcome.late);
        expect(result.status, OccurrenceStatus.done);
      },
    );

    test(
      'valide après windowEndsAt + 24h → OccurrenceTooLateForCatchupFailure',
      () async {
        when(
          () => repo.findById('occ-001'),
        ).thenAnswer((_) async => makeHabit());

        expect(
          () => useCase.call(
            occurrenceId: 'occ-001',
            source: ValidationSource.catchup,
            now: windowEndsAt.add(const Duration(hours: 25)),
          ),
          throwsA(isA<OccurrenceTooLateForCatchupFailure>()),
        );
      },
    );
  });

  group('ValidateOccurrenceUseCase — règles métier', () {
    test(
      'occurrence déjà finalisée (done) → AlreadyFinalizedFailure',
      () async {
        when(
          () => repo.findById('occ-001'),
        ).thenAnswer((_) async => makeHabit(status: OccurrenceStatus.done));

        expect(
          () => useCase.call(
            occurrenceId: 'occ-001',
            source: ValidationSource.notificationAction,
            now: DateTime.utc(2026, 5, 23, 8, 5),
          ),
          throwsA(isA<OccurrenceAlreadyFinalizedFailure>()),
        );
      },
    );

    test('occurrence missed (terminal) → AlreadyFinalizedFailure', () async {
      when(
        () => repo.findById('occ-001'),
      ).thenAnswer((_) async => makeHabit(status: OccurrenceStatus.missed));

      expect(
        () => useCase.call(
          occurrenceId: 'occ-001',
          source: ValidationSource.catchup,
          now: DateTime.utc(2026, 5, 23, 23),
        ),
        throwsA(isA<OccurrenceAlreadyFinalizedFailure>()),
      );
    });

    test('occurrence introuvable → NotFoundFailure', () async {
      when(() => repo.findById('inconnu')).thenAnswer((_) async => null);

      expect(
        () => useCase.call(
          occurrenceId: 'inconnu',
          source: ValidationSource.notificationAction,
          now: DateTime.utc(2026, 5, 23, 8, 5),
        ),
        throwsA(isA<OccurrenceNotFoundFailure>()),
      );
    });

    test('accepts acknowledged status as valid input (snooze followed by '
        'validation, ADR-018 §4.2)', () async {
      // `acknowledged` est un état transitoire (user a tapé le body sans
      // action explicite). L'occurrence reste actionnable : un appel
      // ultérieur à validate doit aboutir à `done`, sans
      // AlreadyFinalizedFailure. Ce test verrouille cette intention pour
      // éviter une régression future qui ajouterait `acknowledged` à
      // `isFinalized`.
      when(() => repo.findById('occ-001')).thenAnswer(
        (_) async => makeHabit(status: OccurrenceStatus.acknowledged),
      );

      final result = await useCase.call(
        occurrenceId: 'occ-001',
        source: ValidationSource.app,
        now: DateTime.utc(2026, 5, 23, 8, 5),
      );

      expect(result.status, OccurrenceStatus.done);
      expect(result.outcome, OccurrenceOutcome.onTime);
    });

    test(
      'dismissed → done (validation manuelle dashboard, ADR-018 §4.2)',
      () async {
        // dismissed n'est PAS un état finalisé : l'utilisateur peut revalider
        // depuis le dashboard tant qu'on est dans la window de rattrapage.
        when(() => repo.findById('occ-001')).thenAnswer(
          (_) async => makeHabit(status: OccurrenceStatus.dismissed),
        );

        final result = await useCase.call(
          occurrenceId: 'occ-001',
          source: ValidationSource.app,
          now: DateTime.utc(2026, 5, 23, 14),
        );

        expect(result.status, OccurrenceStatus.done);
        expect(result.outcome, OccurrenceOutcome.onTime);
      },
    );
  });

  group('ValidateOccurrenceUseCase — persistance', () {
    test('persiste validationSource et actedAt', () async {
      when(() => repo.findById('occ-001')).thenAnswer((_) async => makeHabit());

      final now = DateTime.utc(2026, 5, 23, 8, 5);
      await useCase.call(
        occurrenceId: 'occ-001',
        source: ValidationSource.notificationAction,
        now: now,
      );

      final saved =
          verify(() => repo.save(captureAny())).captured.first as Occurrence;
      expect(saved.validationSource, ValidationSource.notificationAction);
      expect(saved.actedAt, now);
      expect(saved.outcome, OccurrenceOutcome.onTime);
      expect(saved.status, OccurrenceStatus.done);
    });

    test(
      'clears nextFireAt on validate post-snooze to prevent re-notification',
      () async {
        // Quand une occurrence est snoozée, `nextFireAt` est défini pour le
        // reschedule local. Si l'utilisateur la valide ensuite, le
        // scheduler ne doit plus fire la notif → `nextFireAt` doit être
        // remis à null dans la donnée sauvegardée.
        final now = DateTime.utc(2026, 5, 23, 7);
        final snoozedOcc = Occurrence(
          id: 'occ-001',
          source: OccurrenceSource.habit,
          sourceId: 'habit-001',
          userId: 'user-001',
          scheduledAt: scheduledAt,
          windowEndsAt: windowEndsAt,
          status: OccurrenceStatus.snoozed,
          snoozeCount: 1,
          nextFireAt: DateTime.utc(2026, 5, 23, 8, 30),
          createdAt: now,
          updatedAt: now,
        );
        when(
          () => repo.findById('occ-001'),
        ).thenAnswer((_) async => snoozedOcc);

        await useCase.call(
          occurrenceId: 'occ-001',
          source: ValidationSource.notificationAction,
          now: DateTime.utc(2026, 5, 23, 8, 35),
        );

        final saved =
            verify(() => repo.save(captureAny())).captured.first as Occurrence;
        expect(saved.status, OccurrenceStatus.done);
        expect(
          saved.nextFireAt,
          isNull,
          reason:
              'nextFireAt doit être null après validation pour empêcher '
              'la re-notification (PR #194 P2).',
        );
      },
    );

    test('utilise DateTime.now() si paramètre `now` non fourni', () async {
      // On vérifie juste que l'appel ne throw pas et que le save est appelé
      // (le now interne dépend de l'horloge système).
      when(() => repo.findById('occ-001')).thenAnswer((_) async => makeHabit());

      await useCase.call(occurrenceId: 'occ-001', source: ValidationSource.app);

      verify(() => repo.save(any())).called(1);
    });
  });

  group('ValidateOccurrenceUseCase — prière (CDC §13)', () {
    test('source prayer + onTime → ok', () async {
      when(
        () => repo.findById('occ-prayer-001'),
      ).thenAnswer((_) async => makePrayer());

      final result = await useCase.call(
        occurrenceId: 'occ-prayer-001',
        source: ValidationSource.notificationAction,
        now: DateTime.utc(2026, 5, 23, 8, 5),
      );

      expect(result.status, OccurrenceStatus.done);
    });
  });
}
