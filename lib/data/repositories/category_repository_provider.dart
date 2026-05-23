import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:murabbi_mobile/core/network/supabase_client_wrapper.dart';
import 'package:murabbi_mobile/data/datasources/category_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_category_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_impl.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart'
    show kUseInMemoryHabitRepository;
import 'package:murabbi_mobile/data/repositories/in_memory_habit_repository.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';

/// Provider Riverpod du datasource Categories (issue #149).
final categoryDataSourceProvider = Provider<CategoryDataSource>((ref) {
  return SupabaseCategoryDataSource(
    ref.watch(supabaseClientProvider),
    wrapper: ref.watch(supabaseClientWrapperProvider),
  );
});

/// Provider Riverpod du `CategoryRepository`.
///
/// Défaut : [CategoryRepositoryImpl] adossé à Supabase. Partage le flag
/// [kUseInMemoryHabitRepository] pour rester cohérent avec le repository
/// Habits en mode dev offline.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  if (kUseInMemoryHabitRepository) {
    return InMemoryCategoryRepository();
  }
  return CategoryRepositoryImpl(ref.watch(categoryDataSourceProvider));
});
