import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_user_data_source.dart';
import 'package:murabbi_mobile/data/datasources/user_data_source.dart';
import 'package:murabbi_mobile/data/repositories/user_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/user_repository.dart';

/// Provider Riverpod du datasource User (ST-02 — écriture profil).
final userDataSourceProvider = Provider<UserDataSource>((ref) {
  return SupabaseUserDataSource(ref.watch(supabaseClientProvider));
});

/// Provider Riverpod du `UserRepository`. La couche presentation consomme
/// uniquement ce provider (l'interface domain), jamais l'impl ni le
/// datasource directement.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userDataSourceProvider));
});
