import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Convertit une row `daily_niyyahs` en [DailyNiyyah].
///
/// Colonnes attendues : `user_id`, `day`, `text`.
class NiyyahMapper {
  const NiyyahMapper._();

  static DailyNiyyah fromRow(Map<String, dynamic> row) {
    return DailyNiyyah(
      userId: UserId(row['user_id'] as String),
      date: DateTime.parse(row['day'] as String),
      text: NonEmptyString(row['text'] as String),
    );
  }
}
