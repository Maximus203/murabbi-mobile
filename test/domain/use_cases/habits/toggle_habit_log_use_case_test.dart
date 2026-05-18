import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/toggle_habit_log_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';

class _MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late _MockHabitRepository repo;
  final habitId = HabitId('habit-001');
  final date = DateTime.utc(2026, 5, 17);

  setUpAll(() {
    registerFallbackValue(HabitId('fallback'));
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(HabitLogStatus.onTime);
  });

  setUp(() {
    repo = _MockHabitRepository();
    when(
      () => repo.toggleHabitLog(
        habitId: any(named: 'habitId'),
        date: any(named: 'date'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async {});
  });

  group('ToggleHabitLogUseCase.nextStatus — cycle', () {
    test('null → onTime', () {
      expect(ToggleHabitLogUseCase.nextStatus(null), HabitLogStatus.onTime);
    });

    test('missed → onTime', () {
      expect(
        ToggleHabitLogUseCase.nextStatus(HabitLogStatus.missed),
        HabitLogStatus.onTime,
      );
    });

    test('onTime → late', () {
      expect(
        ToggleHabitLogUseCase.nextStatus(HabitLogStatus.onTime),
        HabitLogStatus.late,
      );
    });

    test('late → missed', () {
      expect(
        ToggleHabitLogUseCase.nextStatus(HabitLogStatus.late),
        HabitLogStatus.missed,
      );
    });

    test('cycle complet null → done → late → missed → done', () {
      var status = ToggleHabitLogUseCase.nextStatus(null);
      expect(status, HabitLogStatus.onTime);
      status = ToggleHabitLogUseCase.nextStatus(status);
      expect(status, HabitLogStatus.late);
      status = ToggleHabitLogUseCase.nextStatus(status);
      expect(status, HabitLogStatus.missed);
      status = ToggleHabitLogUseCase.nextStatus(status);
      expect(status, HabitLogStatus.onTime);
    });
  });

  group('ToggleHabitLogUseCase.call', () {
    test('persiste le next status calculé depuis le current', () async {
      final next = await ToggleHabitLogUseCase(repo).call(
        habitId: habitId,
        date: date,
        currentStatus: HabitLogStatus.onTime,
      );

      expect(next, HabitLogStatus.late);
      verify(
        () => repo.toggleHabitLog(
          habitId: habitId,
          date: date,
          status: HabitLogStatus.late,
        ),
      ).called(1);
    });

    test('null current → persiste onTime et retourne onTime', () async {
      final next = await ToggleHabitLogUseCase(
        repo,
      ).call(habitId: habitId, date: date, currentStatus: null);

      expect(next, HabitLogStatus.onTime);
      verify(
        () => repo.toggleHabitLog(
          habitId: habitId,
          date: date,
          status: HabitLogStatus.onTime,
        ),
      ).called(1);
    });
  });
}
