import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/habit_data_source.dart';
import 'package:murabbi_mobile/data/mappers/habit_mapper.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockHabitDataSource extends Mock implements HabitDataSource {}

void main() {
  late _MockHabitDataSource ds;
  late HabitRepositoryImpl repo;

  const userIdValue = '11111111-1111-1111-1111-111111111111';

  Habit habitFixture({String id = 'habit-1'}) => Habit(
    id: HabitId(id),
    name: NonEmptyString('Lire le Coran'),
    categoryId: CategoryId('cat-religion'),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: const {1, 2, 3, 4, 5, 6, 7},
    points: HabitPoints(5),
    isSystem: false,
  );

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    ds = _MockHabitDataSource();
    repo = HabitRepositoryImpl(ds);
  });

  group('getHabits', () {
    test('returns an empty list when no rows exist', () async {
      when(() => ds.getHabits(userIdValue)).thenAnswer((_) async => []);
      final habits = await repo.getHabits(UserId(userIdValue));
      expect(habits, isEmpty);
    });

    test('maps rows to Habit entities', () async {
      when(
        () => ds.getHabits(userIdValue),
      ).thenAnswer((_) async => [HabitMapper.toRow(habitFixture())]);
      final habits = await repo.getHabits(UserId(userIdValue));
      expect(habits, hasLength(1));
      expect(habits.first.id, HabitId('habit-1'));
    });
  });

  group('createHabit', () {
    test('returns the created habit with a non-null id', () async {
      final habit = habitFixture();
      when(
        () => ds.createHabit(any()),
      ).thenAnswer((_) async => HabitMapper.toRow(habit));
      final created = await repo.createHabit(
        userId: UserId(userIdValue),
        habit: habit,
      );
      expect(created.id, HabitId('habit-1'));
      final captured =
          verify(() => ds.createHabit(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['user_id'], userIdValue);
    });
  });

  group('updateHabit', () {
    test('forwards updated data to the datasource', () async {
      final habit = habitFixture();
      when(
        () => ds.updateHabit(any()),
      ).thenAnswer((_) async => HabitMapper.toRow(habit));
      final updated = await repo.updateHabit(habit);
      expect(updated.id, habit.id);
      verify(() => ds.updateHabit(any())).called(1);
    });
  });

  group('deleteHabit', () {
    test('delegates to the datasource', () async {
      when(() => ds.deleteHabit('habit-1')).thenAnswer((_) async {});
      await repo.deleteHabit(HabitId('habit-1'));
      verify(() => ds.deleteHabit('habit-1')).called(1);
    });
  });

  group('toggleHabitLog — via RPC (#164)', () {
    test(
      '#164 toggle réussi → délègue à ds.toggleHabitLog et retourne',
      () async {
        when(
          () => ds.toggleHabitLog(
            habitId: 'habit-1',
            date: DateTime.utc(2026, 5, 9),
            status: 'ontime',
          ),
        ).thenAnswer(
          (_) async => {'habit_id': 'habit-1', 'date': '2026-05-09'},
        );

        await repo.toggleHabitLog(
          habitId: HabitId('habit-1'),
          date: DateTime.utc(2026, 5, 9),
          status: HabitLogStatus.onTime,
        );

        verify(
          () => ds.toggleHabitLog(
            habitId: 'habit-1',
            date: DateTime.utc(2026, 5, 9),
            status: 'ontime',
          ),
        ).called(1);
      },
    );

    test(
      '#164 HabitFutureLogNotAllowedFailure propagée telle quelle',
      () async {
        when(
          () => ds.toggleHabitLog(
            habitId: any(named: 'habitId'),
            date: any(named: 'date'),
            status: any(named: 'status'),
          ),
        ).thenThrow(
          const HabitFailure.futureLogNotAllowed(
            message: 'Impossible de logger une date future',
          ),
        );

        expect(
          () => repo.toggleHabitLog(
            habitId: HabitId('habit-1'),
            date: DateTime.utc(2099, 1, 1),
            status: HabitLogStatus.onTime,
          ),
          throwsA(isA<HabitFutureLogNotAllowedFailure>()),
        );
      },
    );

    test('#164 HabitBackdateTooOldFailure propagée telle quelle', () async {
      when(
        () => ds.toggleHabitLog(
          habitId: any(named: 'habitId'),
          date: any(named: 'date'),
          status: any(named: 'status'),
        ),
      ).thenThrow(
        const HabitFailure.backdateTooOld(
          message: 'Rétrodatation limitée à 8 jours',
        ),
      );

      expect(
        () => repo.toggleHabitLog(
          habitId: HabitId('habit-1'),
          date: DateTime.utc(2020, 1, 1),
          status: HabitLogStatus.onTime,
        ),
        throwsA(isA<HabitBackdateTooOldFailure>()),
      );
    });

    test(
      '#164 ancien appel upsertHabitLog absent — méthode toggleHabitLog utilisée',
      () async {
        // Vérifie que upsertHabitLog n'est PAS appelé lors d'un toggleHabitLog.
        when(
          () => ds.toggleHabitLog(
            habitId: any(named: 'habitId'),
            date: any(named: 'date'),
            status: any(named: 'status'),
          ),
        ).thenAnswer((_) async => {});

        await repo.toggleHabitLog(
          habitId: HabitId('habit-1'),
          date: DateTime.utc(2026, 5, 9),
          status: HabitLogStatus.onTime,
        );

        verifyNever(() => ds.upsertHabitLog(any()));
      },
    );
  });

  group('logHabit', () {
    test('passes v1.5 fields to the datasource', () async {
      when(() => ds.upsertHabitLog(any())).thenAnswer((_) async {});
      await repo.logHabit(
        HabitLog(
          habitId: HabitId('habit-1'),
          date: DateTime.utc(2026, 5, 9),
          status: HabitLogStatus.late,
          actualValue: 12,
          targetReached: true,
          duration: const Duration(seconds: 600),
        ),
      );
      final captured =
          verify(() => ds.upsertHabitLog(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['actual_value'], 12);
      expect(captured['target_reached'], true);
      expect(captured['duration_seconds'], 600);
    });
  });

  group('getLogsForHabit', () {
    test('forwards the date range and maps rows', () async {
      when(
        () => ds.getLogsForHabit(
          habitId: 'habit-1',
          from: '2026-05-01',
          to: '2026-05-09',
        ),
      ).thenAnswer(
        (_) async => [
          {'habit_id': 'habit-1', 'date': '2026-05-02', 'status': 'ontime'},
        ],
      );
      final logs = await repo.getLogsForHabit(
        habitId: HabitId('habit-1'),
        from: DateTime.utc(2026, 5, 1),
        to: DateTime.utc(2026, 5, 9),
      );
      expect(logs, hasLength(1));
      expect(logs.first.status, HabitLogStatus.onTime);
    });
  });
}
