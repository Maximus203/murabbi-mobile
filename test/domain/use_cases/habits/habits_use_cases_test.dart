import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/create_habit_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/delete_habit_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/get_habits_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/toggle_habit_log_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/update_habit_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late MockHabitRepository mockRepo;
  final userId = UserId('user-uuid-001');

  final testHabit = Habit(
    id: HabitId('habit-uuid-001'),
    name: NonEmptyString('Morning run'),
    categoryId: CategoryId('cat-uuid-001'),
    frequency: 5,
    timeRange: HabitTimeRange.morning,
    activeDays: {1, 2, 3, 4, 5},
    points: HabitPoints(5),
    isSystem: false,
  );

  setUp(() {
    mockRepo = MockHabitRepository();
    registerFallbackValue(testHabit);
    registerFallbackValue(HabitId('fallback-id'));
  });

  group('GetHabitsUseCase', () {
    late GetHabitsUseCase useCase;

    setUp(() => useCase = GetHabitsUseCase(mockRepo));

    test('calls repository.getHabits and returns list', () async {
      when(() => mockRepo.getHabits(userId))
          .thenAnswer((_) async => [testHabit]);

      final result = await useCase(userId);

      expect(result, [testHabit]);
      verify(() => mockRepo.getHabits(userId)).called(1);
    });
  });

  group('CreateHabitUseCase', () {
    late CreateHabitUseCase useCase;

    setUp(() => useCase = CreateHabitUseCase(mockRepo));

    test('calls repository.createHabit and returns created habit', () async {
      when(() => mockRepo.createHabit(userId: userId, habit: testHabit))
          .thenAnswer((_) async => testHabit);

      final result = await useCase(userId: userId, habit: testHabit);

      expect(result, testHabit);
      verify(() => mockRepo.createHabit(userId: userId, habit: testHabit))
          .called(1);
    });
  });

  group('UpdateHabitUseCase', () {
    late UpdateHabitUseCase useCase;

    setUp(() => useCase = UpdateHabitUseCase(mockRepo));

    test('calls repository.updateHabit and returns updated habit', () async {
      when(() => mockRepo.updateHabit(testHabit))
          .thenAnswer((_) async => testHabit);

      final result = await useCase(testHabit);

      expect(result, testHabit);
      verify(() => mockRepo.updateHabit(testHabit)).called(1);
    });
  });

  group('DeleteHabitUseCase', () {
    late DeleteHabitUseCase useCase;
    final habitId = HabitId('habit-uuid-001');

    setUp(() => useCase = DeleteHabitUseCase(mockRepo));

    test('calls repository.deleteHabit with habitId', () async {
      when(() => mockRepo.deleteHabit(habitId)).thenAnswer((_) async {});

      await useCase(habitId);

      verify(() => mockRepo.deleteHabit(habitId)).called(1);
    });
  });

  group('ToggleHabitLogUseCase', () {
    late ToggleHabitLogUseCase useCase;
    final habitId = HabitId('habit-uuid-001');
    final date = DateTime(2026, 4, 27);

    setUp(() => useCase = ToggleHabitLogUseCase(mockRepo));

    test('calls repository.toggleHabitLog with correct params', () async {
      when(
        () => mockRepo.toggleHabitLog(
          habitId: habitId,
          date: date,
          status: HabitLogStatus.done,
        ),
      ).thenAnswer((_) async {});

      await useCase(
        habitId: habitId,
        date: date,
        status: HabitLogStatus.done,
      );

      verify(
        () => mockRepo.toggleHabitLog(
          habitId: habitId,
          date: date,
          status: HabitLogStatus.done,
        ),
      ).called(1);
    });
  });
}
