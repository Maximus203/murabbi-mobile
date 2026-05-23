import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/habit_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_habit_data_source.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_impl.dart';
import 'package:murabbi_mobile/data/repositories/in_memory_habit_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';

/// Bascule entre l'implémentation Supabase (production, défaut) et le
/// scaffold in-memory (dev offline). Mettre à `true` pour retomber sur
/// l'ancien `InMemoryHabitRepository` sans dépendre du backend.
const bool kUseInMemoryHabitRepository = false;

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
///
/// Défaut : [HabitRepositoryImpl] adossé à Supabase. Le flag
/// [kUseInMemoryHabitRepository] permet de retomber sur le scaffold.
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  if (kUseInMemoryHabitRepository) {
    return InMemoryHabitRepository();
  }
  return HabitRepositoryImpl(ref.watch(habitDataSourceProvider));
});
