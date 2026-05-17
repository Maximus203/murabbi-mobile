import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_filter.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';

/// Notifier de l'état de filtre/tri/recherche de HA-01 (issue #94).
///
/// Séparé de [HabitsNotifier] : ce dernier ne gère que le chargement de la
/// liste brute, ce notifier ne gère que les critères d'affichage. Les deux
/// sont combinés par [filteredHabitsProvider].
class HabitsFilterNotifier extends Notifier<HabitsFilter> {
  @override
  HabitsFilter build() => const HabitsFilter();

  /// Met à jour la requête de recherche full-text.
  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  /// Met à jour le filtre par statut.
  void setStatus(HabitFilterStatus status) {
    state = state.copyWith(status: status);
  }

  /// Met à jour le critère de tri.
  void setSortBy(HabitSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }
}

/// État courant des critères de filtre/tri/recherche HA-01.
final habitsFilterProvider =
    NotifierProvider<HabitsFilterNotifier, HabitsFilter>(
      HabitsFilterNotifier.new,
    );

/// Liste d'habitudes filtrée/triée — combine [habitsNotifierProvider]
/// (données brutes) et [habitsFilterProvider] (critères).
///
/// Retourne une liste vide tant que les données ne sont pas chargées.
/// Performance : filtrage 100% côté client — acceptable pour <= 100 items
/// (cf. acceptance criteria #94). Au-delà, basculer côté serveur.
final filteredHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitsNotifierProvider).valueOrNull ?? const [];
  final filter = ref.watch(habitsFilterProvider);
  return filter.apply(habits);
});
