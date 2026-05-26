import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/data/repositories/daily_summary_repository_provider.dart';
import 'package:murabbi_mobile/domain/use_cases/score/compute_streak_delta_use_case.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

/// Delta de streak hebdomadaire de l'utilisateur courant (issue #6, Phase 5).
///
/// Δstreak = streak(aujourd'hui) − streak(aujourd'hui − 7 jours).
///
/// Retourne :
/// - `0` si aucun utilisateur connecté
/// - `0` si historique vide (première semaine)
/// - `0` en cas d'erreur réseau (fallback défensif — la tuile STREAK reste
///   propre plutôt que de crasher le dashboard)
/// - valeur réelle sinon (positive = progression, négative = régression)
///
/// Consomme [currentUserProvider] comme point d'override unique pour les
/// tests (cf. ADR-016, §override unique par feature).
final streakDeltaProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  try {
    final repo = ref.watch(dailySummaryRepositoryProvider);
    final now = DateTime.now();
    final history = await repo.getRecentSummaries(user.id, days: 30);
    return const ComputeStreakDeltaUseCase()(
      history: history,
      referenceDate: now,
    );
  } catch (e, st) {
    appLog.w(
      'streakDeltaProvider: calcul impossible',
      error: e,
      stackTrace: st,
    );
    return 0;
  }
});
