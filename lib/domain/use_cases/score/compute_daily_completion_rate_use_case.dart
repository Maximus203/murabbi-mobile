import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Retourne le taux de complétion journalier (0.0 à 100.0) depuis
/// `daily_summaries`. Valeur calculée côté Supabase (GENERATED STORED).
class ComputeDailyCompletionRateUseCase {
  final DailySummaryRepository _repo;

  const ComputeDailyCompletionRateUseCase(this._repo);

  Future<double> call(UserId userId) async {
    final summary = await _repo.getTodaySummary(userId);
    if (summary == null) return 0.0;
    return summary.completionRate;
  }
}
