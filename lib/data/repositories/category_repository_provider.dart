import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_category_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_impl.dart';
import 'package:murabbi_mobile/data/repositories/current_user_id_resolver_provider.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';

/// Provider Riverpod du datasource Categories (issue #149).
final categoryDataSourceProvider = Provider<CategoryDataSource>((ref) {
  return SupabaseCategoryDataSource(
    ref.watch(supabaseClientProvider),
    wrapper: ref.watch(supabaseClientWrapperProvider),
  );
});

/// Provider Riverpod du `CategoryRepository`. La couche presentation consomme
/// uniquement ce provider (l'interface domain), jamais l'impl ni le
/// datasource directement.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(
    ref.watch(categoryDataSourceProvider),
    currentUserIdResolver: ref.watch(currentUserIdResolverProvider),
  );
});
