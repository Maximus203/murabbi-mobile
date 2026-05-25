import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/habit_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_habit_data_source.dart';
import 'package:murabbi_mobile/data/repositories/current_user_id_resolver_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';

/// Provider Riverpod du datasource Habits (issue #149).
final habitDataSourceProvider = Provider<HabitDataSource>((ref) {
  return SupabaseHabitDataSource(
    ref.watch(supabaseClientProvider),
    wrapper: ref.watch(supabaseClientWrapperProvider),
  );
});

/// Provider Riverpod du `HabitRepository`. La couche presentation consomme
/// uniquement ce provider (l'interface domain), jamais l'impl ni le
/// datasource directement.
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepositoryImpl(
    ref.watch(habitDataSourceProvider),
    currentUserIdResolver: ref.watch(currentUserIdResolverProvider),
  );
});
