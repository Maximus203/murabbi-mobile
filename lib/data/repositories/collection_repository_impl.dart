import 'package:murabbi_mobile/data/datasources/collection_data_source.dart';
import 'package:murabbi_mobile/data/mappers/collection_mapper.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Implémentation Supabase du [CollectionRepository] — délègue à un
/// [CollectionDataSource] et passe par `CollectionMapper` pour la
/// sérialisation. Suit le pattern `HabitRepositoryImpl` (#149).
///
/// Le contrat de soft-delete (`deleted_at IS NULL`) est honoré dans le
/// datasource (`getCollections`).
class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionDataSource _ds;

  const CollectionRepositoryImpl(this._ds);

  @override
  Future<List<Collection>> getCollections(UserId userId) async {
    final rows = await _ds.getCollections(userId.value);
    return rows.map(CollectionMapper.fromRow).toList(growable: false);
  }

  @override
  Future<void> activateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) {
    return _ds.activateCollection(
      userId: userId.value,
      collectionId: collectionId.value,
    );
  }

  @override
  Future<void> deactivateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) {
    return _ds.deactivateCollection(
      userId: userId.value,
      collectionId: collectionId.value,
    );
  }

  @override
  Future<Collection> createCollection({
    required UserId userId,
    required Collection collection,
  }) async {
    final row = CollectionMapper.toRow(collection)
      ..['created_by'] = userId.value;
    final created = await _ds.createCollection(row);
    final newId = created['id'] as String;

    // Lie les habitudes choisies dans la table de jonction.
    await _ds.linkHabits(
      collectionId: newId,
      habitIds: collection.habitIds.map((h) => h.value).toList(),
    );

    // Recompose l'entité persistée à partir de la row créée + habitIds
    // d'origine (la jonction vient d'être écrite).
    return CollectionMapper.fromRow({
      ...created,
      'collection_habits': collection.habitIds
          .map((h) => {'habit_id': h.value})
          .toList(),
      'user_collections': const <dynamic>[],
    });
  }
}
