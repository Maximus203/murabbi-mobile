import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class PrayerDay extends Equatable {
  final UserId userId;
  final DateTime date;
  final PrayerStatus fajr;
  final PrayerStatus dhuhr;
  final PrayerStatus asr;
  final PrayerStatus maghrib;
  final PrayerStatus isha;

  const PrayerDay({
    required this.userId,
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  @override
  List<Object?> get props => [userId, date, fajr, dhuhr, asr, maghrib, isha];
}
