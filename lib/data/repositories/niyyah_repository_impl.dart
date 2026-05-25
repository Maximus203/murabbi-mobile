import 'package:murabbi_mobile/data/datasources/supabase/supabase_niyyah_data_source.dart';
import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class NiyyahRepositoryImpl implements NiyyahRepository {
  final SupabaseNiyyahDataSource _ds;

  const NiyyahRepositoryImpl(this._ds);

  @override
  Future<DailyNiyyah?> getTodayNiyyah(UserId userId) async {
    final row = await _ds.getTodayNiyyah(userId.value);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<DailyNiyyah> setTodayNiyyah({
    required UserId userId,
    required NonEmptyString text,
  }) async {
    final row = await _ds.setTodayNiyyah(userId.value, text.value);
    return _fromRow(row);
  }

  DailyNiyyah _fromRow(Map<String, dynamic> row) => DailyNiyyah(
        userId: UserId(row['user_id'] as String),
        date: DateTime.parse(row['day'] as String),
        text: NonEmptyString(row['text'] as String),
      );
}
