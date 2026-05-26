import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/daily_summary_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/use_cases/score/get_daily_summary_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

final getDailySummaryUseCaseProvider = Provider<GetDailySummaryUseCase>((ref) {
  return GetDailySummaryUseCase(ref.watch(dailySummaryRepositoryProvider));
});

/// Résumé du jour de l'utilisateur connecté — alimente la score card et la grille de stats.
///
/// `null` si aucun utilisateur authentifié ou si aucune activité n'a encore
/// été enregistrée ce jour.
final dailySummaryProvider = FutureProvider<DailySummary?>((ref) async {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(getDailySummaryUseCaseProvider).call(user.id);
});
