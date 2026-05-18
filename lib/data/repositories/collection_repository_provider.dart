import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_collection_data_source.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';

/// Provider du datasource Collections (Supabase).
final collectionDataSourceProvider = Provider<SupabaseCollectionDataSource>((
  ref,
) {
  return SupabaseCollectionDataSourceImpl(ref.watch(supabaseClientProvider));
});

/// Provider du [CollectionRepository]. La couche presentation ne consomme que
/// ce provider (l'interface domain), jamais l'impl ni le datasource directement.
final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(ref.watch(collectionDataSourceProvider));
});
