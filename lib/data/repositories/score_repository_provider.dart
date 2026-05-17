import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/datasources/score_data_source.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_client_provider.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_score_data_source.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_impl.dart';
import 'package:murabbi_mobile/domain/repositories/score_repository.dart';

/// Provider Riverpod du datasource Score (issue #6, Phase 5).
final scoreDataSourceProvider = Provider<ScoreDataSource>((ref) {
  return SupabaseScoreDataSource(ref.watch(supabaseClientProvider));
});

/// Provider Riverpod du `ScoreRepository`. La couche presentation consomme
/// uniquement ce provider (l'interface domain), jamais l'impl ni le
/// datasource directement.
final scoreRepositoryProvider = Provider<ScoreRepository>((ref) {
  return ScoreRepositoryImpl(ref.watch(scoreDataSourceProvider));
});
