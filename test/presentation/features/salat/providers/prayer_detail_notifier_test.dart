import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_history_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/mark_prayer_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_detail_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';

class _MockPrayerRepository extends Mock implements PrayerRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(PrayerStatus.pending);
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(UserId('fallback'));
  });

  late _MockPrayerRepository repo;
  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  final clockNow = DateTime.utc(2026, 5, 14, 14, 30);
  final today = DateTime.utc(2026, 5, 14);

  setUp(() {
    repo = _MockPrayerRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        clockProvider.overrideWithValue(() => clockNow),
        getPrayerHistoryUseCaseProvider.overrideWithValue(
          GetPrayerHistoryUseCase(repo),
        ),
        markPrayerUseCaseProvider.overrideWithValue(MarkPrayerUseCase(repo)),
      ],
    );
  }

  PrayerDay dayWithFajr(DateTime d, PrayerStatus fajr) => PrayerDay(
    userId: testUser.id,
    date: d,
    fajr: fajr,
    dhuhr: PrayerStatus.pending,
    asr: PrayerStatus.pending,
    maghrib: PrayerStatus.pending,
    isha: PrayerStatus.pending,
  );

  test(
    'build() retourne 7 jours, padding pending pour les jours manquants',
    () async {
      // Le repo renvoie seulement 2 jours sur 7.
      when(
        () => repo.getPrayerHistory(
          userId: any(named: 'userId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => [
          dayWithFajr(today, PrayerStatus.onTime),
          dayWithFajr(
            today.subtract(const Duration(days: 3)),
            PrayerStatus.late,
          ),
        ],
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        prayerDetailNotifierProvider('fajr').future,
      );

      expect(state.prayerName, 'fajr');
      expect(state.weekDays, hasLength(7));
      // Today (index 6) = onTime, J-3 (index 3) = late, autres = pending.
      expect(state.weekStatuses[6], PrayerStatus.onTime);
      expect(state.weekStatuses[3], PrayerStatus.late);
      expect(state.weekStatuses[0], PrayerStatus.pending);
    },
  );

  test('weekStatuses projette le bon champ selon prayerName', () async {
    when(
      () => repo.getPrayerHistory(
        userId: any(named: 'userId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => [
        PrayerDay(
          userId: testUser.id,
          date: today,
          fajr: PrayerStatus.onTime,
          dhuhr: PrayerStatus.late,
          asr: PrayerStatus.makeup,
          maghrib: PrayerStatus.missed,
          isha: PrayerStatus.pending,
        ),
      ],
    );

    final container = makeContainer();
    addTearDown(container.dispose);

    for (final entry in <String, PrayerStatus>{
      'fajr': PrayerStatus.onTime,
      'dhuhr': PrayerStatus.late,
      'asr': PrayerStatus.makeup,
      'maghrib': PrayerStatus.missed,
      'isha': PrayerStatus.pending,
    }.entries) {
      final state = await container.read(
        prayerDetailNotifierProvider(entry.key).future,
      );
      expect(state.weekStatuses.last, entry.value, reason: entry.key);
    }
  });

  test(
    'markDay() applique la mise à jour optimiste immédiatement (D-29)',
    () async {
      when(
        () => repo.getPrayerHistory(
          userId: any(named: 'userId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [dayWithFajr(today, PrayerStatus.pending)]);

      // markPrayer prend du temps — on vérifie que l'UI voit déjà le
      // statut optimiste avant la fin de l'opération réseau.
      final markCompleter = Completer<void>();
      when(
        () => repo.markPrayer(
          userId: any(named: 'userId'),
          date: any(named: 'date'),
          prayerName: any(named: 'prayerName'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) => markCompleter.future);

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(prayerDetailNotifierProvider('fajr').future);

      // Lance markDay sans await — on veut lire l'état optimiste.
      final markFuture = container
          .read(prayerDetailNotifierProvider('fajr').notifier)
          .markDay(dayUtc: today, status: PrayerStatus.onTime);

      // Après le premier microtask (après l'update optimiste synchrone),
      // l'état doit déjà refléter onTime — sans attendre markCompleter.
      await Future<void>.microtask(() {});
      final optimisticState =
          container.read(prayerDetailNotifierProvider('fajr')).requireValue;
      expect(optimisticState.weekStatuses.last, PrayerStatus.onTime);
      expect(
        container.read(prayerDetailNotifierProvider('fajr')).isLoading,
        isFalse,
        reason: 'Pas de spinner pendant la mise à jour optimiste',
      );

      // Finalise la persistence.
      markCompleter.complete();
      await markFuture;

      // L'état reste onTime après confirmation réseau.
      final finalState =
          container.read(prayerDetailNotifierProvider('fajr')).requireValue;
      expect(finalState.weekStatuses.last, PrayerStatus.onTime);
    },
  );

  test(
    'markDay() rollback si la persistence échoue (D-29)',
    () async {
      when(
        () => repo.getPrayerHistory(
          userId: any(named: 'userId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => [dayWithFajr(today, PrayerStatus.pending)]);
      when(
        () => repo.markPrayer(
          userId: any(named: 'userId'),
          date: any(named: 'date'),
          prayerName: any(named: 'prayerName'),
          status: any(named: 'status'),
        ),
      ).thenThrow(Exception('Network error'));

      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(prayerDetailNotifierProvider('fajr').future);

      await container
          .read(prayerDetailNotifierProvider('fajr').notifier)
          .markDay(dayUtc: today, status: PrayerStatus.onTime);

      // Après l'échec, l'état revient à pending (rollback).
      final rollbackState =
          container.read(prayerDetailNotifierProvider('fajr')).requireValue;
      expect(rollbackState.weekStatuses.last, PrayerStatus.pending);
    },
  );

  test('markDay() appelle MarkPrayer pour la bonne prière', () async {
    when(
      () => repo.getPrayerHistory(
        userId: any(named: 'userId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => [dayWithFajr(today, PrayerStatus.pending)]);
    when(
      () => repo.markPrayer(
        userId: any(named: 'userId'),
        date: any(named: 'date'),
        prayerName: any(named: 'prayerName'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async {});

    final container = makeContainer();
    addTearDown(container.dispose);

    await container.read(prayerDetailNotifierProvider('fajr').future);

    await container
        .read(prayerDetailNotifierProvider('fajr').notifier)
        .markDay(dayUtc: today, status: PrayerStatus.onTime);

    final state = container
        .read(prayerDetailNotifierProvider('fajr'))
        .requireValue;
    expect(state.weekStatuses.last, PrayerStatus.onTime);
    verify(
      () => repo.markPrayer(
        userId: testUser.id,
        date: today,
        prayerName: 'fajr',
        status: PrayerStatus.onTime,
      ),
    ).called(1);
  });

  test('build() lève StateError si aucun user authentifié', () async {
    when(
      () => repo.getPrayerHistory(
        userId: any(named: 'userId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => []);

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        clockProvider.overrideWithValue(() => clockNow),
        getPrayerHistoryUseCaseProvider.overrideWithValue(
          GetPrayerHistoryUseCase(repo),
        ),
        markPrayerUseCaseProvider.overrideWithValue(MarkPrayerUseCase(repo)),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(prayerDetailNotifierProvider('fajr').future),
      throwsA(isA<StateError>()),
    );
  });
}
