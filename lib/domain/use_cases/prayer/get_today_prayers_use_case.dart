import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class GetTodayPrayersUseCase {
  final PrayerRepository _repository;
  const GetTodayPrayersUseCase(this._repository);

  Future<PrayerDay> call(UserId userId) => _repository.getTodayPrayers(userId);
}
