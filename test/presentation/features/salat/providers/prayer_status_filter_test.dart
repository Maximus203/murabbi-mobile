import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_status_filter.dart';

void main() {
  group('PrayerStatusFilter — libellés', () {
    test('expose les 4 libellés dans l\'ordre attendu', () {
      expect(PrayerStatusFilter.values.map((f) => f.label), [
        'Toutes',
        'À faire',
        'Faites',
        'Manquées',
      ]);
    });
  });

  group('PrayerStatusFilter — matches', () {
    test('all accepte tous les statuts', () {
      for (final s in PrayerStatus.values) {
        expect(PrayerStatusFilter.all.matches(s), isTrue);
      }
    });

    test('todo accepte uniquement pending', () {
      expect(PrayerStatusFilter.todo.matches(PrayerStatus.pending), isTrue);
      expect(PrayerStatusFilter.todo.matches(PrayerStatus.onTime), isFalse);
      expect(PrayerStatusFilter.todo.matches(PrayerStatus.missed), isFalse);
    });

    test('done accepte onTime, late et makeup', () {
      expect(PrayerStatusFilter.done.matches(PrayerStatus.onTime), isTrue);
      expect(PrayerStatusFilter.done.matches(PrayerStatus.late), isTrue);
      expect(PrayerStatusFilter.done.matches(PrayerStatus.makeup), isTrue);
      expect(PrayerStatusFilter.done.matches(PrayerStatus.pending), isFalse);
      expect(PrayerStatusFilter.done.matches(PrayerStatus.missed), isFalse);
    });

    test('missed accepte uniquement missed', () {
      expect(PrayerStatusFilter.missed.matches(PrayerStatus.missed), isTrue);
      expect(PrayerStatusFilter.missed.matches(PrayerStatus.onTime), isFalse);
      expect(PrayerStatusFilter.missed.matches(PrayerStatus.pending), isFalse);
    });
  });
}
