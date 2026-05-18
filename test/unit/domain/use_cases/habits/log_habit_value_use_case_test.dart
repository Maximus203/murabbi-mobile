import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/log_habit_value_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';

class _MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late _MockHabitRepository repo;
  late LogHabitValueUseCase useCase;
  final habitId = HabitId('habit-001');
  final date = DateTime.utc(2026, 5, 18);

  setUpAll(() {
    registerFallbackValue(
      HabitLog(
        habitId: HabitId('fallback'),
        date: DateTime.utc(2026),
        status: HabitLogStatus.onTime,
      ),
    );
  });

  setUp(() {
    repo = _MockHabitRepository();
    useCase = LogHabitValueUseCase(repo);
    when(() => repo.logHabit(any())).thenAnswer((_) async {});
  });

  group('LogHabitValueUseCase —', () {
    test('actualValue == targetValue → targetReached = true', () async {
      await useCase.call(
        habitId: habitId,
        date: date,
        actualValue: 5,
        targetValue: 5,
      );
      final log =
          verify(() => repo.logHabit(captureAny())).captured.first as HabitLog;
      expect(log.targetReached, isTrue);
      expect(log.actualValue, 5);
      expect(log.status, HabitLogStatus.onTime);
    });

    test('actualValue > targetValue → targetReached = true (dépassé)', () async {
      await useCase.call(
        habitId: habitId,
        date: date,
        actualValue: 7,
        targetValue: 5,
      );
      final log =
          verify(() => repo.logHabit(captureAny())).captured.first as HabitLog;
      expect(log.targetReached, isTrue);
      expect(log.actualValue, 7);
    });

    test('actualValue < targetValue → targetReached = false', () async {
      await useCase.call(
        habitId: habitId,
        date: date,
        actualValue: 3,
        targetValue: 5,
      );
      final log =
          verify(() => repo.logHabit(captureAny())).captured.first as HabitLog;
      expect(log.targetReached, isFalse);
      expect(log.actualValue, 3);
    });

    test('actualValue = 0 → log persisté, targetReached = false', () async {
      await useCase.call(
        habitId: habitId,
        date: date,
        actualValue: 0,
        targetValue: 5,
      );
      final log =
          verify(() => repo.logHabit(captureAny())).captured.first as HabitLog;
      expect(log.actualValue, 0);
      expect(log.targetReached, isFalse);
    });

    test('duration transmise intacte au HabitLog', () async {
      const dur = Duration(minutes: 12, seconds: 34);
      await useCase.call(
        habitId: habitId,
        date: date,
        actualValue: 20,
        targetValue: 20,
        duration: dur,
      );
      final log =
          verify(() => repo.logHabit(captureAny())).captured.first as HabitLog;
      expect(log.duration, dur);
    });

    test('loggedAt est renseigné à now UTC', () async {
      final before = DateTime.now().toUtc();
      await useCase.call(
        habitId: habitId,
        date: date,
        actualValue: 5,
        targetValue: 5,
      );
      final after = DateTime.now().toUtc();
      final log =
          verify(() => repo.logHabit(captureAny())).captured.first as HabitLog;
      expect(log.loggedAt, isNotNull);
      expect(log.loggedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(
          log.loggedAt!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('habitId et date transmis intacts', () async {
      await useCase.call(
        habitId: habitId,
        date: date,
        actualValue: 1,
        targetValue: 1,
      );
      final log =
          verify(() => repo.logHabit(captureAny())).captured.first as HabitLog;
      expect(log.habitId, habitId);
      expect(log.date, date);
    });
  });
}
