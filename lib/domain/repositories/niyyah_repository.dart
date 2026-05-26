import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class NiyyahRepository {
  Future<DailyNiyyah?> getTodayNiyyah(UserId userId);

  Future<DailyNiyyah> setTodayNiyyah({
    required UserId userId,
    required NonEmptyString text,
  });
}
