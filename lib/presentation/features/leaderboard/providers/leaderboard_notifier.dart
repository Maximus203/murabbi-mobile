import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

/// Provider du notifier Leaderboard — top 50 scores hebdomadaires.
///
/// Utilise [AsyncNotifierProvider] legacy (cf. ADR-016).
/// Retourne une liste vide si l'utilisateur n'est pas authentifié.
final leaderboardNotifierProvider =
    AsyncNotifierProvider<LeaderboardNotifier, List<UserScore>>(
  LeaderboardNotifier.new,
);

/// Notifier du leaderboard hebdomadaire.
///
/// Charge les 50 premiers scores via [ScoreRepository.getLeaderboard].
/// Expose [refresh] pour forcer un rechargement (pull-to-refresh).
class LeaderboardNotifier extends AsyncNotifier<List<UserScore>> {
  static const _limit = 50;

  @override
  Future<List<UserScore>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    return ref.read(scoreRepositoryProvider).getLeaderboard(limit: _limit);
  }

  /// Force un rechargement du classement.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
