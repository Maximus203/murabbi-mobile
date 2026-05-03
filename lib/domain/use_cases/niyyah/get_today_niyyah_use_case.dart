import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class GetTodayNiyyahUseCase {
  final NiyyahRepository _repository;

  const GetTodayNiyyahUseCase(this._repository);

  Future<DailyNiyyah?> call(UserId userId) =>
      _repository.getTodayNiyyah(userId);
}
