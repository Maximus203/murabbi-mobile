import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/use_cases/score/get_leaderboard_use_case.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

/// Taille de page du classement hebdomadaire (issue #6 — pagination
/// obligatoire, aucun SELECT non borné).
const int kLeaderboardPageSize = 50;

/// Use case `GetLeaderboard` exposé via Riverpod (issue #6, Phase 5).
final getLeaderboardUseCaseProvider = Provider<GetLeaderboardUseCase>((ref) {
  return GetLeaderboardUseCase(ref.watch(scoreRepositoryProvider));
});

/// Classement hebdomadaire — alimente LB-01.
///
/// `AsyncNotifier` pour exposer [refresh] (pull-to-refresh). Retourne `[]`
/// si l'utilisateur n'est pas connecté. Borné à [kLeaderboardPageSize]
/// entrées (pagination obligatoire).
class LeaderboardNotifier extends AsyncNotifier<List<UserScore>> {
  @override
  Future<List<UserScore>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    return ref
        .watch(getLeaderboardUseCaseProvider)
        .call(limit: kLeaderboardPageSize);
  }

  /// Recharge le classement (pull-to-refresh LB-01).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);
      if (user == null) return const [];
      return ref
          .read(getLeaderboardUseCaseProvider)
          .call(limit: kLeaderboardPageSize);
    });
  }
}

final leaderboardNotifierProvider =
    AsyncNotifierProvider<LeaderboardNotifier, List<UserScore>>(
      LeaderboardNotifier.new,
    );

/// Alias pour la compatibilité des consommateurs existants.
final leaderboardProvider = leaderboardNotifierProvider;
