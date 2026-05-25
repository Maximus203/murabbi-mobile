import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/local/pending_sync_item.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habit_detail_notifier.dart';
import 'package:murabbi_mobile/services/connectivity/connectivity_service.dart';
import 'package:murabbi_mobile/services/sync/sync_service.dart';
import 'package:murabbi_mobile/services/sync/sync_service_provider.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockHabitRepo extends Mock implements HabitRepository {}

class _MockSyncService extends Mock implements SyncService {}

/// Stub [ConnectivityService] — retourne `isOnline = true` par défaut.
class _StubConnectivityService implements ConnectivityService {
  final bool online;
  const _StubConnectivityService({this.online = true});

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> onConnectivityChanged() => Stream.value(online);
}

void main() {
  late _MockAuthRepo authRepo;
  late _MockHabitRepo habitRepo;

  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  Habit makeHabit(String id) => Habit(
    id: HabitId(id),
    name: NonEmptyString('Lecture Coran'),
    categoryId: CategoryId('cat-religion'),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: const {1, 2, 3, 4, 5, 6, 7},
    points: HabitPoints(5),
    isSystem: false,
  );

  setUpAll(() {
    registerFallbackValue(UserId('fallback'));
    registerFallbackValue(HabitId('fallback'));
    registerFallbackValue(DateTime.utc(2026, 1, 1));
    registerFallbackValue(HabitLogStatus.onTime);
    registerFallbackValue(
      HabitLog(
        habitId: HabitId('fallback'),
        date: DateTime.utc(2026),
        status: HabitLogStatus.onTime,
      ),
    );
    registerFallbackValue(
      PendingSyncItem(
        id: 'fallback',
        type: SyncItemType.logHabit,
        payload: const {},
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    authRepo = _MockAuthRepo();
    habitRepo = _MockHabitRepo();
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => testUser);
    when(
      () => habitRepo.getHabits(any()),
    ).thenAnswer((_) async => [makeHabit('h1')]);
    when(
      () => habitRepo.getLogsForHabit(
        habitId: any(named: 'habitId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => <HabitLog>[]);
    when(() => habitRepo.deleteHabit(any())).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer({
    _MockSyncService? syncService,
    bool online = true,
  }) {
    final mockSync = syncService ?? _MockSyncService();

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        habitRepositoryProvider.overrideWithValue(habitRepo),
        syncServiceProvider.overrideWithValue(mockSync),
        connectivityServiceProvider.overrideWithValue(
          _StubConnectivityService(online: online),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('build charge habit + stats + recentLogs', () async {
    final container = makeContainer();
    final state = await container.read(
      habitDetailNotifierProvider('h1').future,
    );
    expect(state.habit.id.value, 'h1');
    expect(state.stats.heatmapData.length, 30);
    expect(state.recentLogs, isEmpty);
  });

  test('recentLogs limité à 7 entrées max', () async {
    final logs = [
      for (var i = 0; i < 12; i++)
        HabitLog(
          habitId: HabitId('h1'),
          date: DateTime.utc(2026, 5, 17).subtract(Duration(days: i)),
          status: HabitLogStatus.onTime,
        ),
    ];
    when(
      () => habitRepo.getLogsForHabit(
        habitId: any(named: 'habitId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => logs);

    final container = makeContainer();
    final state = await container.read(
      habitDetailNotifierProvider('h1').future,
    );
    expect(state.recentLogs.length, 7);
  });

  test('build émet une erreur si habit introuvable', () async {
    final container = makeContainer();
    await expectLater(
      container.read(habitDetailNotifierProvider('introuvable').future),
      throwsA(isA<StateError>()),
    );
  });

  test('deleteHabit appelle DeleteHabitUseCase', () async {
    final container = makeContainer();
    await container.read(habitDetailNotifierProvider('h1').future);
    await container
        .read(habitDetailNotifierProvider('h1').notifier)
        .deleteHabit();
    verify(() => habitRepo.deleteHabit(HabitId('h1'))).called(1);
  });

  // ── logHabit (M2 — Optimistic UI + sync queue) ────────────────────────────

  group('logHabit (M2 optimistic UI)', () {
    late _MockSyncService mockSync;

    setUp(() {
      mockSync = _MockSyncService();
      when(
        () => mockSync.enqueueLogHabit(
          habitId: any(named: 'habitId'),
          userId: any(named: 'userId'),
          status: any(named: 'status'),
          date: any(named: 'date'),
          actualValue: any(named: 'actualValue'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSync.processPendingQueue()).thenAnswer((_) async {});
      when(() => mockSync.pendingCount).thenAnswer((_) => Stream.value(0));
      when(
        () => mockSync.deadLetterStream,
      ).thenAnswer((_) => const Stream.empty());
    });

    test('applique une mise à jour optimiste immédiate', () async {
      final container = makeContainer(syncService: mockSync);
      await container.read(habitDetailNotifierProvider('h1').future);

      // Avant logHabit : aucun log
      expect(
        container.read(habitDetailNotifierProvider('h1')).value!.recentLogs,
        isEmpty,
      );

      // Appel sans attente (optimistic = synchrone depuis le point de vue state)
      final future = container
          .read(habitDetailNotifierProvider('h1').notifier)
          .logHabit(HabitLogStatus.onTime);

      // L'état est mis à jour immédiatement (avant l'await du future).
      expect(
        container.read(habitDetailNotifierProvider('h1')).value!.recentLogs,
        hasLength(1),
      );

      await future;
    });

    test('appelle SyncService.enqueueLogHabit', () async {
      final container = makeContainer(syncService: mockSync);
      await container.read(habitDetailNotifierProvider('h1').future);

      await container
          .read(habitDetailNotifierProvider('h1').notifier)
          .logHabit(HabitLogStatus.onTime);

      verify(
        () => mockSync.enqueueLogHabit(
          habitId: 'h1',
          userId: any(named: 'userId'),
          status: HabitLogStatus.onTime,
          date: any(named: 'date'),
          actualValue: any(named: 'actualValue'),
        ),
      ).called(1);
    });

    test('appelle processPendingQueue si online', () async {
      final container = makeContainer(syncService: mockSync, online: true);
      await container.read(habitDetailNotifierProvider('h1').future);

      await container
          .read(habitDetailNotifierProvider('h1').notifier)
          .logHabit(HabitLogStatus.onTime);

      verify(() => mockSync.processPendingQueue()).called(1);
    });

    test("n'appelle pas processPendingQueue si offline", () async {
      final container = makeContainer(syncService: mockSync, online: false);
      await container.read(habitDetailNotifierProvider('h1').future);

      await container
          .read(habitDetailNotifierProvider('h1').notifier)
          .logHabit(HabitLogStatus.onTime);

      verifyNever(() => mockSync.processPendingQueue());
    });

    test(
      'nappelle pas directement habitRepo.logHabit (sync différée)',
      () async {
        final container = makeContainer(syncService: mockSync);
        await container.read(habitDetailNotifierProvider('h1').future);

        await container
            .read(habitDetailNotifierProvider('h1').notifier)
            .logHabit(HabitLogStatus.onTime);

        // Le log passe par la sync queue, jamais directement par le repo.
        verifyNever(() => habitRepo.logHabit(any()));
      },
    );
  });
}
