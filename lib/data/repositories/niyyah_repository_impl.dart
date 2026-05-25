import 'package:murabbi_mobile/data/datasources/supabase/supabase_niyyah_data_source.dart';
import 'package:murabbi_mobile/data/mappers/niyyah_mapper.dart';
import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation Supabase du [NiyyahRepository].
///
/// Délègue à [SupabaseNiyyahDataSource] et traduit les rows en entités
/// via [NiyyahMapper]. Pattern `PrayerRepositoryImpl`.
class NiyyahRepositoryImpl implements NiyyahRepository {
  final SupabaseNiyyahDataSource _ds;

  const NiyyahRepositoryImpl(this._ds);

  @override
  Future<DailyNiyyah?> getTodayNiyyah(UserId userId) => _guard(() async {
    final row = await _ds.getTodayNiyyah(userId.value);
    return row == null ? null : NiyyahMapper.fromRow(row);
  });

  @override
  Future<DailyNiyyah> setTodayNiyyah({
    required UserId userId,
    required NonEmptyString text,
  }) => _guard(() async {
    final row = await _ds.setTodayNiyyah(userId.value, text.value);
    return NiyyahMapper.fromRow(row);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on sb.PostgrestException catch (e) {
      throw Exception('Niyyah database error: ${e.code ?? ''} ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}
