import 'package:murabbi_mobile/data/datasources/supabase/supabase_daily_summary_data_source.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class DailySummaryRepositoryImpl implements DailySummaryRepository {
  final SupabaseDailySummaryDataSource _ds;

  const DailySummaryRepositoryImpl(this._ds);

  @override
  Future<DailySummary?> getTodaySummary(String userId) =>
      _guard(() async {
        final row = await _ds.getTodaySummary(userId);
        return row == null ? null : _fromRow(row);
      });

  @override
  Future<List<DailySummary>> getRecentSummaries(
    String userId, {
    int days = 30,
  }) =>
      _guard(() async {
        final rows = await _ds.getRecentSummaries(userId, days: days);
        return rows.map(_fromRow).toList(growable: false);
      });

  DailySummary _fromRow(Map<String, dynamic> row) => DailySummary(
        userId: row['user_id'] as String,
        day: DateTime.parse(row['day'] as String),
        totalItems: (row['total_items'] as num).toInt(),
        doneItems: (row['done_items'] as num).toInt(),
        completionRate: (row['completion_rate'] as num).toDouble(),
        streakValid: row['streak_valid'] as bool? ?? false,
      );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on sb.PostgrestException {
      rethrow;
    }
  }
}
