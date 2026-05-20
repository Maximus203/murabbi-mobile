import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

class Collection extends Equatable {
  final CollectionId id;
  final NonEmptyString name;
  final NonEmptyString description;
  final List<HabitId> habitIds;
  final bool isSystem;
  final bool isActive;

  /// Public Supabase Storage URL of the collection cover.
  ///
  /// Source: `product_decisions_v1.md § Q-13-cover` (verrouillé 2026-05-03).
  /// `null` ⇔ no cover uploaded — UI must render the
  /// [CollectionCoverFallback] gradient (see [BuildCollectionCoverUseCase]).
  final String? coverImageUrl;

  /// Catégorie principale choisie lors de la création (CO-02, Q-23).
  /// Nullable — optionnel côté UI ; stocké dans `public.collections` via AR-04.
  final CategoryId? primaryCategoryId;

  /// Nom d'icône Lucide kebab-case choisi lors de la création (CO-02, Q-23).
  /// Nullable — optionnel côté UI ; stocké dans `public.collections` via AR-04.
  final String? icon;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.habitIds,
    required this.isSystem,
    required this.isActive,
    this.coverImageUrl,
    this.primaryCategoryId,
    this.icon,
  }) {
    if (habitIds.isEmpty) {
      throw ArgumentError.value(
        habitIds,
        'habitIds',
        'Collection must contain at least one habit',
      );
    }
  }

  /// Somme des points des habitudes de cette collection présentes dans [habits].
  ///
  /// Calcul client-side (Q-24) — aucune requête réseau. Les habitudes absentes
  /// de [habits] (race condition, suppression) sont ignorées silencieusement.
  int ptsPerDay(List<Habit> habits) {
    final ids = habitIds.map((h) => h.value).toSet();
    return habits
        .where((h) => ids.contains(h.id.value))
        .fold(0, (sum, h) => sum + h.points.value);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    habitIds,
    isSystem,
    isActive,
    coverImageUrl,
    primaryCategoryId,
    icon,
  ];
}
