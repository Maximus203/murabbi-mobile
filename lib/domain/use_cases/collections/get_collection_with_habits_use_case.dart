import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Résultat de [GetCollectionWithHabitsUseCase] : la collection et ses habitudes.
class CollectionWithHabits extends Equatable {
  final Collection collection;
  final List<Habit> habits;

  const CollectionWithHabits({required this.collection, required this.habits});

  @override
  List<Object?> get props => [collection, habits];
}

/// Charge une collection et la liste de ses habitudes en une seule opération.
///
/// Stratégie : charger toutes les collections de l'utilisateur + toutes ses
/// habitudes, puis filtrer côté client. Efficace pour le volume V1 (Top 50).
/// Si le volume augmente, envisager un endpoint Supabase dédié (ADR à créer).
class GetCollectionWithHabitsUseCase {
  final CollectionRepository _collectionRepository;
  final HabitRepository _habitRepository;

  const GetCollectionWithHabitsUseCase({
    required CollectionRepository collectionRepository,
    required HabitRepository habitRepository,
  }) : _collectionRepository = collectionRepository,
       _habitRepository = habitRepository;

  Future<CollectionWithHabits> call({
    required UserId userId,
    required CollectionId collectionId,
  }) async {
    final collections = await _collectionRepository.getCollections(userId);
    final collection = collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => throw StateError(
        'Collection ${collectionId.value} not found for user ${userId.value}',
      ),
    );

    final allHabits = await _habitRepository.getHabits(userId);
    final collectionHabitIdSet = collection.habitIds.toSet();
    final habits = allHabits
        .where((h) => collectionHabitIdSet.contains(h.id))
        .toList();

    return CollectionWithHabits(collection: collection, habits: habits);
  }
}
