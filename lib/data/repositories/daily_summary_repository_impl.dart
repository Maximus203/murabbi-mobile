import 'package:murabbi_mobile/data/datasources/supabase/supabase_daily_summary_data_source.dart';
import 'package:murabbi_mobile/data/mappers/daily_summary_mapper.dart';
import 'package:murabbi_mobile/domain/entities/daily_summary.dart';
import 'package:murabbi_mobile/domain/repositories/daily_summary_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase du [DailySummaryRepository].
///
/// Délègue à [SupabaseDailySummaryDataSource] et traduit les rows en entités
/// via [DailySummaryMapper]. Erreurs natives → exceptions domaine (pattern
/// `PrayerRepositoryImpl`).
class DailySummaryRepositoryImpl implements DailySummaryRepository {
  final SupabaseDailySummaryDataSource _ds;

  const DailySummaryRepositoryImpl(this._ds);

  @override
  Future<DailySummary?> getTodaySummary(UserId userId) => _guard(() async {
    final row = await _ds.getTodaySummary(userId.value);
    return row == null ? null : DailySummaryMapper.fromRow(row);
  });

  @override
  Future<List<DailySummary>> getRecentSummaries(
    UserId userId, {
    int days = 30,
  }) => _guard(() async {
    final rows = await _ds.getRecentSummaries(userId.value, days: days);
    return rows.map(DailySummaryMapper.fromRow).toList(growable: false);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on sb.PostgrestException catch (e) {
      throw Exception('DailySummary database error: ${e.code ?? ''} ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
