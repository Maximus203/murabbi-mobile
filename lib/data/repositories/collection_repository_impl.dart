import 'package:murabbi_mobile/data/datasources/collection_data_source.dart';
import 'package:murabbi_mobile/data/mappers/collection_mapper.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/errors/collection_failure.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase du [CollectionRepository] — délègue à un
/// [CollectionDataSource] et passe par `CollectionMapper` pour la
/// sérialisation. Suit le pattern `PrayerRepositoryImpl` (#149) :
/// les exceptions natives sont traduites en [CollectionFailure] typées,
/// jamais laissées remonter brutes.
///
/// Le contrat de soft-delete (`deleted_at IS NULL`) est honoré dans le
/// datasource (`getCollections`).
class CollectionRepositoryImpl implements CollectionRepository {
  final CollectionDataSource _ds;

  const CollectionRepositoryImpl(this._ds);

  @override
  Future<List<Collection>> getCollections(UserId userId) => _guard(() async {
    final rows = await _ds.getCollections(userId.value);
    return rows.map(CollectionMapper.fromRow).toList(growable: false);
  });

  @override
  Future<void> activateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) => _guard(
    () => _ds.activateCollection(
      userId: userId.value,
      collectionId: collectionId.value,
    ),
  );

  @override
  Future<void> deactivateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) => _guard(
    () => _ds.deactivateCollection(
      userId: userId.value,
      collectionId: collectionId.value,
    ),
  );

  @override
  Future<Collection> createCollection({
    required UserId userId,
    required Collection collection,
  }) => _guard(() async {
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
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on CollectionFailure {
      rethrow;
    } on sb.PostgrestException catch (e) {
      throw CollectionFailure.database(message: '${e.code ?? ''} ${e.message}');
    } catch (e) {
      throw _translate(e);
    }
  }

  CollectionFailure _translate(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('rate_limit') ||
        msg.contains('rate limit')) {
      return CollectionFailure.network(message: error.toString());
    }
    return CollectionFailure.unknown(message: error.toString());
  }
}
