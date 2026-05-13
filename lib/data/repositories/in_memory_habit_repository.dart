import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Implémentation **in-memory** des repositories Habits et Categories.
///
/// **Statut V1 (slice 3.D dev scaffold)** : permet de livrer les UI HA-01 /
/// HA-02 / CA-01 fonctionnelles sur device sans dépendre du SQL Supabase
/// (les colonnes v15 — target, subtasks, time range, points — ne sont pas
/// encore exposées dans le datasource Supabase mobile).
///
/// **Remplacement Supabase** : à brancher en suite dans une slice dédiée
/// `feat/data-habit-supabase-datasource` :
///   1. SupabaseHabitsDataSource + mapper (cf. admin migration align_mobile_domain)
///   2. HabitRepositoryImpl déléguant au datasource
///   3. Override le provider ci-dessous via `habitRepositoryProvider.overrideWithValue(...)`
class InMemoryHabitRepository implements HabitRepository {
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
  Future<void> deleteHabit(HabitId habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
  }

  @override
  Future<void> toggleHabitLog({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus status,
  }) async {
    // No-op in V1 dev scaffold — log history n'est pas affichée en HA-01.
  }

  @override
  Future<void> logHabit(HabitLog log) async {
    // No-op in V1 dev scaffold (cf. ci-dessus).
  }

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

/// Implémentation in-memory du `CategoryRepository`. Pré-seedée avec les 5
/// catégories système (cf. AppColors.category*) — l'utilisateur peut en
/// créer d'autres au runtime (perdues au redémarrage).
class InMemoryCategoryRepository implements CategoryRepository {
  static List<Category> _seed() {
    return [
      Category(
        id: CategoryId('cat-religion'),
        name: NonEmptyString('Religion'),
        color: HexColor('#8B6F47'),
        icon: 'moon-star',
        isSystem: true,
      ),
      Category(
        id: CategoryId('cat-sport'),
        name: NonEmptyString('Sport'),
        color: HexColor('#6B8C6B'),
        icon: 'dumbbell',
        isSystem: true,
      ),
      Category(
        id: CategoryId('cat-sante'),
        name: NonEmptyString('Santé'),
        color: HexColor('#5C7A8C'),
        icon: 'heart-pulse',
        isSystem: true,
      ),
      Category(
        id: CategoryId('cat-mental'),
        name: NonEmptyString('Mental'),
        color: HexColor('#7A6B8C'),
        icon: 'brain',
        isSystem: true,
      ),
      Category(
        id: CategoryId('cat-social'),
        name: NonEmptyString('Social'),
        color: HexColor('#9B7A4A'),
        icon: 'users',
        isSystem: true,
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
}

/// Provider Riverpod du repository Habits (V1 in-memory dev scaffold).
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final repo = InMemoryHabitRepository();
  // Note: `ref.keepAlive()` est par défaut pour Provider sans autoDispose,
  // ce qui garantit la persistance du store en mémoire entre les widgets.
  return repo;
});

/// Provider Riverpod du repository Categories (V1 in-memory).
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return InMemoryCategoryRepository();
});
