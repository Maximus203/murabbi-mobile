import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/painting.dart' show Color;
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/errors/category_failure.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

/// Implémentation **in-memory** de [HabitRepository] — dev scaffold déplacé
/// en `test/helpers/` (P6 : n'a pas sa place dans `lib/`).
class InMemoryHabitRepository implements HabitRepository {
  InMemoryHabitRepository() {
    assert(
      kDebugMode || kProfileMode,
      'InMemoryHabitRepository est un dev scaffold. '
      'Il ne doit pas être actif en release build.',
    );
  }

  final List<Habit> _habits = [];

  @override
  Future<List<Habit>> getHabits(UserId userId) async => List.of(_habits);

  @override
  Future<Habit> createHabit({
    required UserId userId,
    required Habit habit,
  }) async {
    _habits.add(habit);
    return habit;
  }

  @override
  Future<Habit> updateHabit(Habit habit) async {
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx == -1) {
      throw StateError('Habit not found: ${habit.id}');
    }
    _habits[idx] = habit;
    return habit;
  }

  @override
  Future<void> deleteHabit(HabitId habitId, UserId userId) async {
    _habits.removeWhere((h) => h.id == habitId);
  }

  @override
  Future<void> toggleHabitLog({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus status,
  }) async {}

  @override
  Future<void> logHabit(HabitLog log) async {}

  @override
  Future<List<HabitLog>> getLogsForHabit({
    required HabitId habitId,
    required DateTime from,
    required DateTime to,
  }) async => const [];

  @override
  Future<List<HabitSubtask>> getSubtasks(HabitId habitId) async {
    final habit = _habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw StateError('Habit not found: $habitId'),
    );
    return habit.subtasks;
  }

  @override
  Future<HabitSubtask> addSubtask(HabitSubtask subtask) async => subtask;

  @override
  Future<HabitSubtask> updateSubtask(HabitSubtask subtask) async => subtask;

  @override
  Future<void> deleteSubtask(HabitSubtaskId subtaskId) async {}

  @override
  Future<void> reorderSubtasks({
    required HabitId habitId,
    required List<HabitSubtaskId> orderedIds,
  }) async {}
}

/// Implémentation in-memory de [CategoryRepository] — pré-seedée avec les 5
/// catégories système.
class InMemoryCategoryRepository implements CategoryRepository {
  InMemoryCategoryRepository() {
    assert(
      kDebugMode || kProfileMode,
      'InMemoryCategoryRepository est un dev scaffold. '
      'Il ne doit pas être actif en release build.',
    );
  }

  static String _colorToHex(Color c) {
    final argb = c.toARGB32();
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static List<Category> _seed() {
    return [
      Category(
        id: CategoryId('cat-religion'),
        name: NonEmptyString('Religion'),
        color: HexColor(_colorToHex(AppColors.categoryReligion)),
        icon: 'moon-star',
        isSystem: true,
        slug: 'religion',
      ),
      Category(
        id: CategoryId('cat-sport'),
        name: NonEmptyString('Sport'),
        color: HexColor(_colorToHex(AppColors.categorySport)),
        icon: 'dumbbell',
        isSystem: true,
        slug: 'sport',
      ),
      Category(
        id: CategoryId('cat-sante'),
        name: NonEmptyString('Santé'),
        color: HexColor(_colorToHex(AppColors.categorySante)),
        icon: 'heart-pulse',
        isSystem: true,
        slug: 'sante',
      ),
      Category(
        id: CategoryId('cat-mental'),
        name: NonEmptyString('Mental'),
        color: HexColor(_colorToHex(AppColors.categoryMental)),
        icon: 'brain',
        isSystem: true,
        slug: 'mental',
      ),
      Category(
        id: CategoryId('cat-social'),
        name: NonEmptyString('Social'),
        color: HexColor(_colorToHex(AppColors.categorySocial)),
        icon: 'users',
        isSystem: true,
        slug: 'social',
      ),
    ];
  }

  final List<Category> _categories = _seed();

  @override
  Future<List<Category>> getCategories(UserId userId) async =>
      List.of(_categories);

  @override
  Future<Category> createCategory({
    required UserId userId,
    required Category category,
  }) async {
    _categories.add(category);
    return category;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx == -1) {
      throw StateError('Category not found: ${category.id}');
    }
    _categories[idx] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(CategoryId categoryId, UserId userId) async {
    _categories.removeWhere((c) => c.id == categoryId);
  }

  @override
  Future<Category> getCategoryBySlug(UserId userId, String slug) async {
    try {
      return _categories.firstWhere((c) => c.slug == slug);
    } on StateError {
      throw CategoryFailure.notFound(message: 'No category with slug "$slug"');
    }
  }
}
