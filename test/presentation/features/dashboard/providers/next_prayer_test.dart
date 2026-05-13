import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/next_prayer.dart';

void main() {
  final day = DateTime.utc(2026, 5, 12);
  final times = PrayerTimes(
    fajr: day.add(const Duration(hours: 4, minutes: 12)),
    sunrise: day.add(const Duration(hours: 5, minutes: 50)),
    dhuhr: day.add(const Duration(hours: 13, minutes: 51)),
    asr: day.add(const Duration(hours: 17, minutes: 49)),
    maghrib: day.add(const Duration(hours: 21, minutes: 36)),
    isha: day.add(const Duration(hours: 23, minutes: 14)),
  );

  group('NextPrayer.from', () {
    test('returns fajr when called before fajr', () {
      final r = NextPrayer.from(
        times: times,
        now: day.add(const Duration(hours: 3)),
      );
      expect(r!.name, 'fajr');
      expect(r.isTomorrow, isFalse);
    });

    test('returns dhuhr after fajr but before dhuhr', () {
      final r = NextPrayer.from(
        times: times,
        now: day.add(const Duration(hours: 10)),
      );
      expect(r!.name, 'dhuhr');
    });

    test('returns asr right after dhuhr', () {
      final r = NextPrayer.from(
        times: times,
        now: day.add(const Duration(hours: 14)),
      );
      expect(r!.name, 'asr');
    });

    test('returns isha after maghrib', () {
      final r = NextPrayer.from(
        times: times,
        now: day.add(const Duration(hours: 22)),
      );
      expect(r!.name, 'isha');
    });

    test('returns next-day fajr after isha (with isTomorrow flag)', () {
      final r = NextPrayer.from(
        times: times,
        now: day.add(const Duration(hours: 23, minutes: 59)),
      );
      expect(r!.name, 'fajr');
      expect(r.isTomorrow, isTrue);
      // timeUtc avancé de 24h par rapport au fajr du jour.
      expect(r.timeUtc, equals(times.fajr.add(const Duration(days: 1))));
    });

    test('boundary case : now == fajr returns dhuhr (strictly after)', () {
      final r = NextPrayer.from(times: times, now: times.fajr);
      expect(r!.name, 'dhuhr');
    });
  });
}
