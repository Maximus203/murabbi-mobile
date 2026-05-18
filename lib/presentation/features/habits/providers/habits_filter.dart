import 'package:murabbi_mobile/domain/entities/habit.dart';

/// Critère de tri de la liste d'habitudes HA-01 (issue #94).
enum HabitSortBy {
  /// Tri alphabétique A-Z sur le nom.
  name,

  /// Tri par points décroissant (plus de points en premier).
  points,

  /// Tri par catégorie (ordre alphabétique de `categoryId`).
  category,

  /// Tri par date de création.
  ///
  /// ⚠ L'entité [Habit] n'expose pas de champ `createdAt` en V1 (cf. rapport
  /// d'audit — colonne présente côté Supabase mais non remontée au domaine).
  /// On utilise `id.value` comme proxy d'ordre d'insertion : les IDs sont
  /// monotones (UUID séquentiels / clés in-memory `h1`, `h2`...). À remplacer
  /// par un vrai `createdAt` quand le champ sera ajouté au domaine.
  createdAt,
}

/// Statut de filtre de la liste d'habitudes HA-01 (issue #94).
enum HabitFilterStatus {
  /// Toutes les habitudes.
  all,

  /// Habitudes programmées le jour de référence (`activeDays` contient le
  /// `weekday` du jour courant).
  active,

  /// Habitudes non programmées le jour de référence.
  inactive,
}

/// État de filtre/tri/recherche de la liste d'habitudes HA-01 (issue #94).
///
/// Objet immuable, logique de filtrage en **Dart pur** (testée unitairement,
/// pas de widget). Appliqué par `filteredHabitsProvider` sur la liste brute
/// remontée par `HabitsNotifier`, sans retoucher ce dernier.
class HabitsFilter {
  /// Requête de recherche full-text (match insensible à la casse sur le nom).
  final String query;

  /// Filtre par statut (toutes / actives / inactives).
  final HabitFilterStatus status;

  /// Critère de tri appliqué après filtrage.
  final HabitSortBy sortBy;

  /// Jour de référence pour le filtre `active`/`inactive`.
  ///
  /// Injectable pour la testabilité — par défaut `DateTime.now()` côté
  /// provider. La logique compare `referenceDate.weekday` à `habit.activeDays`.
  final DateTime? referenceDate;

  const HabitsFilter({
    this.query = '',
    this.status = HabitFilterStatus.all,
    this.sortBy = HabitSortBy.name,
    this.referenceDate,
  });

  /// Retourne une copie avec les champs fournis remplacés.
  HabitsFilter copyWith({
    String? query,
    HabitFilterStatus? status,
    HabitSortBy? sortBy,
    DateTime? referenceDate,
  }) {
    return HabitsFilter(
      query: query ?? this.query,
      status: status ?? this.status,
      sortBy: sortBy ?? this.sortBy,
      referenceDate: referenceDate ?? this.referenceDate,
    );
  }

  /// Applique recherche → filtre statut → tri sur [habits].
  ///
  /// Ne mute jamais la liste d'entrée — retourne une nouvelle liste.
  List<Habit> apply(List<Habit> habits) {
    final trimmedQuery = query.trim().toLowerCase();
    final refWeekday = (referenceDate ?? DateTime.now()).weekday;

    final filtered = habits.where((h) {
      // Recherche full-text sur le nom.
      if (trimmedQuery.isNotEmpty &&
          !h.name.value.toLowerCase().contains(trimmedQuery)) {
        return false;
      }
      // Filtre par statut.
      switch (status) {
        case HabitFilterStatus.all:
          return true;
        case HabitFilterStatus.active:
          return h.activeDays.contains(refWeekday);
        case HabitFilterStatus.inactive:
          return !h.activeDays.contains(refWeekday);
      }
    }).toList();

    _sort(filtered);
    return filtered;
  }

  /// Regroupe [habits] par `categoryId` en conservant l'ordre d'insertion.
  Map<String, List<Habit>> groupByCategory(List<Habit> habits) {
    final groups = <String, List<Habit>>{};
    for (final h in habits) {
      groups.putIfAbsent(h.categoryId.value, () => []).add(h);
    }
    return groups;
  }

  void _sort(List<Habit> habits) {
    switch (sortBy) {
      case HabitSortBy.name:
        habits.sort(
          (a, b) =>
              a.name.value.toLowerCase().compareTo(b.name.value.toLowerCase()),
        );
      case HabitSortBy.points:
        habits.sort((a, b) => b.points.value.compareTo(a.points.value));
      case HabitSortBy.category:
        habits.sort((a, b) => a.categoryId.value.compareTo(b.categoryId.value));
      case HabitSortBy.createdAt:
        // Proxy id.value — cf. doc-comment de [HabitSortBy.createdAt].
        habits.sort((a, b) => a.id.value.compareTo(b.id.value));
    }
  }
}
