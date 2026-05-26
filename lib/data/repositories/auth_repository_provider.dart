import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/auth_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_auth_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return SupabaseAuthDataSource(
    ref.watch(supabaseClientProvider),
    wrapper: ref.watch(supabaseClientWrapperProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDataSourceProvider));
});
