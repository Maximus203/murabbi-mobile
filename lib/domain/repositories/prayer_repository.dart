import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class PrayerRepository {
  Future<PrayerDay> getTodayPrayers(UserId userId);
  Future<void> markPrayer({
    required UserId userId,
    required DateTime date,
    required String prayerName,
    required PrayerStatus status,
  });
  Future<List<PrayerDay>> getPrayerHistory({
    required UserId userId,
    required DateTime from,
    required DateTime to,
  });
}
