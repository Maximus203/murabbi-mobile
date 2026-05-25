import 'package:murabbi_mobile/domain/entities/daily_summary.dart';

abstract interface class DailySummaryRepository {
  /// Résumé pour aujourd'hui — null si aucune occurrence n'a encore été
  /// générée pour ce jour (premier lancement, cron pas encore passé).
  Future<DailySummary?> getTodaySummary(String userId);

  /// [days] derniers jours triés par date DESC — pour le calcul de streak.
  Future<List<DailySummary>> getRecentSummaries(String userId, {int days = 30});
}
