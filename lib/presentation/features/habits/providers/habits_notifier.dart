import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/use_cases/categories/get_categories_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/create_habit_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/get_habits_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Use case providers Habits (slice 3.D dev scaffold).
final getHabitsUseCaseProvider = Provider<GetHabitsUseCase>((ref) {
  return GetHabitsUseCase(ref.watch(habitRepositoryProvider));
});

final createHabitUseCaseProvider = Provider<CreateHabitUseCase>((ref) {
  return CreateHabitUseCase(ref.watch(habitRepositoryProvider));
});

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  return GetCategoriesUseCase(ref.watch(categoryRepositoryProvider));
});

/// Stream des habitudes de l'utilisateur courant. Recharge automatiquement
/// au signin/signout et après création (`invalidate`).
class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() async {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    if (user == null) return const [];
    return ref.read(getHabitsUseCaseProvider).call(user.id);
  }

  /// Recharge la liste — appelé après une création réussie.
  ///
  /// D-18 (issue #103) : on conserve les données précédentes pendant le
  /// refresh pour éviter le flash de rechargement. `AsyncValue.loading()`
  /// n'est émis que si l'état courant est déjà vide (premier chargement).
  Future<void> refresh() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }
    // Garde les données existantes visibles pendant le refresh — pas de spinner.
    state = AsyncValue.data(state.valueOrNull ?? const []);
    state = await AsyncValue.guard(
      () => ref.read(getHabitsUseCaseProvider).call(user.id),
    );
  }
}

final habitsNotifierProvider =
    AsyncNotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

/// Catégories disponibles — chargées une fois, pas de mutation utilisateur
/// en V1 (CA-02 reporté).
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  // userId est requis par le contrat domain mais le repo in-memory n'en
  // dépend pas — passe une valeur synthétique si non-authenticated (les
  // routes habits sont gardées par auth_redirect de toute façon).
  final userId = user?.id ?? UserId('anonymous');
  return ref.read(getCategoriesUseCaseProvider).call(userId);
});
