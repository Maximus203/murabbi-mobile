import 'package:murabbi_mobile/data/datasources/supabase/supabase_collection_data_source.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/errors/collection_failure.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation du [CollectionRepository] adossée à un
/// [SupabaseCollectionDataSource].
///
/// Délègue les opérations au datasource et traduit les exceptions natives
/// Supabase en [CollectionFailure] typées (pattern aligné sur
/// [PrayerRepositoryImpl]).
class CollectionRepositoryImpl implements CollectionRepository {
  final SupabaseCollectionDataSource _ds;

  const CollectionRepositoryImpl(this._ds);

  @override
  Future<List<Collection>> getCollections(UserId userId) =>
      _guard(() => _ds.getCollections(userId));

  @override
  Future<void> activateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) => _guard(
    () => _ds.activateCollection(collectionId: collectionId, userId: userId),
  );

  @override
  Future<void> deactivateCollection({
    required UserId userId,
    required CollectionId collectionId,
  }) => _guard(
    () => _ds.deactivateCollection(collectionId: collectionId, userId: userId),
  );

  @override
  Future<Collection> createCollection({
    required UserId userId,
    required Collection collection,
  }) => _guard(
    () => _ds.createCollection(collection: collection, userId: userId),
  );

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
        msg.contains('network is unreachable')) {
      return CollectionFailure.network(message: error.toString());
    }
    return CollectionFailure.unknown(message: error.toString());
  }
}
