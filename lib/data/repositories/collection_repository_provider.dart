import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_collection_data_source.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_impl.dart';
import 'package:murabbi_mobile/data/repositories/current_user_id_resolver_provider.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';

/// Provider Riverpod du datasource Collections (issue #6, Phase 5).
///
/// Retourne la nouvelle interface [SupabaseCollectionDataSource] qui expose
/// directement des entités domain (migration issue #162 — published_catalog).
final collectionDataSourceProvider = Provider<SupabaseCollectionDataSource>((
  ref,
) {
  return SupabaseCollectionDataSourceImpl(
    ref.watch(supabaseClientProvider),
    wrapper: ref.watch(supabaseClientWrapperProvider),
  );
});

/// Provider Riverpod du `CollectionRepository`. La couche presentation
/// consomme uniquement ce provider (l'interface domain), jamais l'impl ni
/// le datasource directement.
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(
    ref.watch(collectionDataSourceProvider),
    currentUserIdResolver: ref.watch(currentUserIdResolverProvider),
  );
});
