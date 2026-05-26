import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class DailySummaryRepository {
  Future<DailySummary?> getTodaySummary(UserId userId);

  Future<List<DailySummary>> getRecentSummaries(UserId userId, {int days});
}
