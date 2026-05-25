import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/use_cases/score/get_user_score_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Use case `GetUserScore` exposé via Riverpod (issue #6, Phase 5).
final getUserScoreUseCaseProvider = Provider<GetUserScoreUseCase>((ref) {
  return GetUserScoreUseCase(ref.watch(scoreRepositoryProvider));
});

/// Score de l'utilisateur connecté — alimente la score card HM-01.
///
/// `null` si aucun utilisateur authentifié (l'UI affiche alors un état
/// neutre). Recalculé quand l'auth change.
final userScoreProvider = FutureProvider<UserScore?>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return null;
  final getScore = ref.watch(getUserScoreUseCaseProvider);
  return getScore(user.id);
});
