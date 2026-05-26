import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class GetPrayerHistoryUseCase {
  final PrayerRepository _repository;
  const GetPrayerHistoryUseCase(this._repository);

  Future<List<PrayerDay>> call({
    required UserId userId,
    required DateTime from,
    required DateTime to,
  }) => _repository.getPrayerHistory(userId: userId, from: from, to: to);
}
