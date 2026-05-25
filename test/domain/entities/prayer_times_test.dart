import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';

void main() {
  // Helper : timestamps UTC strictement croissants pour un cas valide.
  PrayerTimes sample({
    DateTime? fajr,
    DateTime? sunrise,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
  }) {
    final base = DateTime.utc(2026, 5, 10);
    return PrayerTimes(
      fajr: fajr ?? base.add(const Duration(hours: 4, minutes: 30)),
      sunrise: sunrise ?? base.add(const Duration(hours: 6, minutes: 15)),
      dhuhr: dhuhr ?? base.add(const Duration(hours: 13, minutes: 45)),
      asr: asr ?? base.add(const Duration(hours: 17, minutes: 30)),
      maghrib: maghrib ?? base.add(const Duration(hours: 21, minutes: 10)),
      isha: isha ?? base.add(const Duration(hours: 22, minutes: 50)),
    );
  }

  group('PrayerTimes — construction', () {
    test('keeps the values it is given', () {
      final t = sample();
      expect(t.fajr.hour, 4);
      expect(t.sunrise.hour, 6);
      expect(t.dhuhr.hour, 13);
      expect(t.asr.hour, 17);
      expect(t.maghrib.hour, 21);
      expect(t.isha.hour, 22);
    });

    test('rejects non-chronological order — fajr after sunrise', () {
      final base = DateTime.utc(2026, 5, 10);
      expect(
        () => PrayerTimes(
          fajr: base.add(const Duration(hours: 7)),
          sunrise: base.add(const Duration(hours: 6)),
          dhuhr: base.add(const Duration(hours: 13)),
          asr: base.add(const Duration(hours: 17)),
          maghrib: base.add(const Duration(hours: 21)),
          isha: base.add(const Duration(hours: 22)),
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-chronological order — asr after maghrib', () {
      final base = DateTime.utc(2026, 5, 10);
      expect(
        () => PrayerTimes(
          fajr: base.add(const Duration(hours: 4)),
          sunrise: base.add(const Duration(hours: 6)),
          dhuhr: base.add(const Duration(hours: 13)),
          asr: base.add(const Duration(hours: 22)),
          maghrib: base.add(const Duration(hours: 21)),
          isha: base.add(const Duration(hours: 23)),
        ),
        throwsArgumentError,
      );
    });
  });

  group('PrayerTimes — equality / copyWith', () {
    test('two instances with identical timestamps are equal', () {
      expect(sample(), equals(sample()));
    });

    test('copyWith replaces only the targeted field', () {
      final t = sample();
      final newFajr = t.fajr.add(const Duration(minutes: 5));
      final t2 = t.copyWith(fajr: newFajr);
      expect(t2.fajr, newFajr);
      expect(t2.sunrise, t.sunrise);
      expect(t2.dhuhr, t.dhuhr);
      expect(t2.asr, t.asr);
      expect(t2.maghrib, t.maghrib);
      expect(t2.isha, t.isha);
      expect(t2, isNot(equals(t)));
    });
  });
}
