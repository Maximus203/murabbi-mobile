import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MarkPrayerUseCase {
  final PrayerRepository _repository;
  const MarkPrayerUseCase(this._repository);

  Future<void> call({
    required UserId userId,
    required DateTime date,
    required String prayerName,
    required PrayerStatus status,
  }) => _repository.markPrayer(
    userId: userId,
    date: date,
    prayerName: prayerName,
    status: status,
  );
}
