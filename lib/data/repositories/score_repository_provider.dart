import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_score_data_source.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';

/// Provider du datasource Score (Supabase).
final scoreDataSourceProvider = Provider<SupabaseScoreDataSource>((ref) {
  return SupabaseScoreDataSourceImpl(ref.watch(supabaseClientProvider));
});

/// Provider du [ScoreRepository]. La couche presentation ne consomme que ce
/// provider (l'interface domain), jamais l'impl ni le datasource directement.
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepositoryImpl(ref.watch(scoreDataSourceProvider));
});
