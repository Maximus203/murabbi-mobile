import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class SetTodayNiyyahUseCase {
  final NiyyahRepository _repository;

  const SetTodayNiyyahUseCase(this._repository);

  Future<DailyNiyyah> call({
    required UserId userId,
    required NonEmptyString text,
  }) => _repository.setTodayNiyyah(userId: userId, text: text);
}
