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

  /// Catégorie principale de la collection (Q-23 — AR-04, migration admin).
  ///
  /// Nullable jusqu'à ce que la colonne `primary_category_id` soit ajoutée
  /// dans Supabase. Le formulaire CO-02 permet de la sélectionner.
  final CategoryId? primaryCategoryId;

  /// Icône Lucide de la collection (Q-23 — AR-04, migration admin).
  ///
  /// Nom kebab-case (ex. `'sun'`, `'book-open'`). Nullable jusqu'à la
  /// migration admin. Le formulaire CO-02 expose le sélecteur d'icône.
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

  /// Points quotidiens estimés de la collection (Q-24 — calcul client).
  ///
  /// Somme de [Habit.points] pour chaque habitude dont l'id figure dans
  /// [habitIds]. Les habitudes non trouvées dans [habits] sont ignorées
  /// (cas race condition ou habitude supprimée).
  int ptsPerDay(List<Habit> habits) {
    final ids = habitIds.map((h) => h.value).toSet();
    return habits
        .where((h) => ids.contains(h.id.value))
        // #163 : points nullable — habitude user sans points contribue 0.
        .fold(0, (sum, h) => sum + (h.points?.value ?? 0));
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
