import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/repositories/pseudonym_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/check_pseudo_available_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/add_subtask_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/delete_subtask_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/get_subtasks_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/persist_reorder_subtasks_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/update_subtask_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';

class _MockHabitRepository extends Mock implements HabitRepository {}

class _MockPseudonymRepository extends Mock implements PseudonymRepository {}

void main() {
  final habitId = HabitId('habit-uuid-001');
  final subtaskId = HabitSubtaskId('s-1');
  final subtask = HabitSubtask(
    id: subtaskId,
    habitId: habitId,
    title: NonEmptyString('Étape 1'),
    orderIndex: 0,
  );

  late _MockHabitRepository habitRepo;
  late _MockPseudonymRepository pseudoRepo;

  setUp(() {
    habitRepo = _MockHabitRepository();
    pseudoRepo = _MockPseudonymRepository();
    registerFallbackValue(subtask);
    registerFallbackValue(Pseudonym('Cherif'));
  });

  group('Subtasks CRUD use cases', () {
    test('GetSubtasksUseCase delegates to repository', () async {
      when(
        () => habitRepo.getSubtasks(habitId),
      ).thenAnswer((_) async => [subtask]);
      final result = await GetSubtasksUseCase(habitRepo)(habitId);
      expect(result, [subtask]);
      verify(() => habitRepo.getSubtasks(habitId)).called(1);
    });

    test('AddSubtaskUseCase delegates to repository', () async {
      when(
        () => habitRepo.addSubtask(subtask),
      ).thenAnswer((_) async => subtask);
      final result = await AddSubtaskUseCase(habitRepo)(subtask);
      expect(result, subtask);
      verify(() => habitRepo.addSubtask(subtask)).called(1);
    });

    test('UpdateSubtaskUseCase delegates to repository', () async {
      when(
        () => habitRepo.updateSubtask(subtask),
      ).thenAnswer((_) async => subtask);
      final result = await UpdateSubtaskUseCase(habitRepo)(subtask);
      expect(result, subtask);
      verify(() => habitRepo.updateSubtask(subtask)).called(1);
    });

    test('DeleteSubtaskUseCase delegates to repository', () async {
      when(() => habitRepo.deleteSubtask(subtaskId)).thenAnswer((_) async {});
      await DeleteSubtaskUseCase(habitRepo)(subtaskId);
      verify(() => habitRepo.deleteSubtask(subtaskId)).called(1);
    });

    test('PersistReorderSubtasksUseCase delegates to repository', () async {
      final ordered = [subtaskId];
      when(
        () => habitRepo.reorderSubtasks(habitId: habitId, orderedIds: ordered),
      ).thenAnswer((_) async {});
      await PersistReorderSubtasksUseCase(habitRepo)(
        habitId: habitId,
        orderedIds: ordered,
      );
      verify(
        () => habitRepo.reorderSubtasks(habitId: habitId, orderedIds: ordered),
      ).called(1);
    });
  });

  group('CheckPseudoAvailableUseCase (Q-10 banlist)', () {
    test('returns true when repo says allowed', () async {
      final pseudo = Pseudonym('Cherif');
      when(() => pseudoRepo.isAllowed(pseudo)).thenAnswer((_) async => true);
      final result = await CheckPseudoAvailableUseCase(pseudoRepo)(pseudo);
      expect(result, isTrue);
    });

    test('returns false when banlist hits', () async {
      final pseudo = Pseudonym('rude');
      when(() => pseudoRepo.isAllowed(pseudo)).thenAnswer((_) async => false);
      final result = await CheckPseudoAvailableUseCase(pseudoRepo)(pseudo);
      expect(result, isFalse);
    });
  });
}
