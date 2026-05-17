import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/use_cases/score/get_leaderboard_use_case.dart';

/// Taille de page du classement hebdomadaire (issue #6 — pagination
/// obligatoire, aucun SELECT non borné).
const int kLeaderboardPageSize = 50;

/// Use case `GetLeaderboard` exposé via Riverpod (issue #6, Phase 5).
final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>((ref) {
  return GetLeaderboardUseCase(ref.watch(scoreRepositoryProvider));
});

/// Classement hebdomadaire — alimente LB-01.
///
/// Borné à [kLeaderboardPageSize] entrées (pagination obligatoire). Le tri
/// par rang est garanti par la vue `weekly_leaderboard` côté datasource.
final leaderboardProvider = FutureProvider<List<UserScore>>((ref) async {
  final getLeaderboard = ref.watch(getLeaderboardUseCaseProvider);
  return getLeaderboard(limit: kLeaderboardPageSize);
});
