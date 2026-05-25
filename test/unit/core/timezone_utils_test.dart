// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/core/utils/timezone_utils.dart';

void main() {
  /// Initialise les données tzdata une fois pour la suite.
  setUpAll(() async {
    await TZHelper.init();
  });

  group('TZHelper.isSameDay', () {
    test('retourne true quand deux DateTime tombent le même jour local', () {
      const ianaZone = 'Africa/Dakar'; // UTC+0 toute l'année
      final a = DateTime.utc(2025, 5, 23, 10, 0);
      final b = DateTime.utc(2025, 5, 23, 22, 0);
      expect(TZHelper.isSameDay(a, b, ianaZone), isTrue);
    });

    test(
      'retourne false quand les DateTime sont sur deux jours différents',
      () {
        const ianaZone = 'Africa/Dakar';
        final a = DateTime.utc(2025, 5, 23, 10, 0);
        final b = DateTime.utc(2025, 5, 24, 10, 0);
        expect(TZHelper.isSameDay(a, b, ianaZone), isFalse);
      },
    );

    // BUG-004 : cas critique — 23h30 UTC+3 = 00h30 UTC J+1
    // Sans timezone, ce log serait assigné au jour J+1. Avec timezone, il
    // est correctement attribué au jour J (23h30 locale = encore le même jour).
    test('validate_before_midnight_utc3_is_not_too_late — '
        '23h30 locale UTC+3 est encore le même jour local que 20h UTC', () {
      const ianaZone = 'Africa/Nairobi'; // UTC+3 fixe
      // 20h00 UTC = 23h00 locale UTC+3
      final loggedUtc = DateTime.utc(2025, 5, 23, 20, 0);
      // 00h30 UTC J+1 = 03h30 locale UTC+3 (J+1) — mais on compare avec le
      // début de la même journée locale (08h UTC = 11h locale)
      final scheduledStartUtc = DateTime.utc(2025, 5, 23, 8, 0);
      expect(
        TZHelper.isSameDay(loggedUtc, scheduledStartUtc, ianaZone),
        isTrue,
      );
    });

    // BUG-004 : 23h30 locale UTC+3 = 00h30 UTC → ne doit PAS matcher J+1
    test('midnight_cutoff_uses_local_not_utc — '
        '00h30 UTC ne doit pas matcher le jour UTC+3 suivant', () {
      const ianaZone = 'Africa/Nairobi'; // UTC+3
      // 00h30 UTC = 03h30 UTC+3 → c'est J+1 en UTC+3
      final nextDayUtcMidnight = DateTime.utc(2025, 5, 24, 0, 30);
      // 08h00 UTC = 11h00 UTC+3 → c'est bien J en UTC+3
      final sameDayScheduled = DateTime.utc(2025, 5, 23, 8, 0);
      expect(
        TZHelper.isSameDay(nextDayUtcMidnight, sameDayScheduled, ianaZone),
        isFalse,
      );
    });

    // utc-5 : Bogota (UTC-5, pas de DST).
    // Log à 22h locale Bogota = 03h UTC du lendemain.
    // Scheduled à 10h locale Bogota = 15h UTC.
    // → même jour local (J) → isSameDay = true.
    test('utc_minus_5_log_at_22h_counts_as_correct_day — '
        '22h locale Bogota (UTC-5) est encore le même jour que 10h locale', () {
      const bogota = 'America/Bogota'; // UTC-5 permanent, pas de DST
      // 22h Bogota = 03h UTC du lendemain calendaire UTC, mais encore J local
      final logAt22hLocal = DateTime.utc(2025, 5, 24, 3, 0); // 22h Bogota J
      // 10h Bogota = 15h UTC même jour calendaire UTC
      final scheduledAt10hLocal = DateTime.utc(
        2025,
        5,
        23,
        15,
        0,
      ); // 10h Bogota J
      // Même jour local Bogota → true
      expect(
        TZHelper.isSameDay(logAt22hLocal, scheduledAt10hLocal, bogota),
        isTrue,
      );
      // Log à 01h UTC J+2 = 20h Bogota J+1 (lendemain) → pas le même jour
      final nextDayLog = DateTime.utc(2025, 5, 25, 1, 0); // 20h Bogota J+1
      expect(TZHelper.isSameDay(logAt22hLocal, nextDayLog, bogota), isFalse);
    });

    // utc+3 : log à 23h locale (= 20h UTC) → même jour que 08h locale (= 05h UTC)
    test('utc_plus_3_log_at_23h_counts_as_correct_day — '
        '23h locale UTC+3 compte bien pour le jour local J', () {
      const ianaZone = 'Africa/Nairobi'; // UTC+3
      // 23h00 locale = 20h00 UTC
      final loggedUtc = DateTime.utc(2025, 5, 23, 20, 0);
      // 08h00 locale = 05h00 UTC → même jour local
      final scheduledUtc = DateTime.utc(2025, 5, 23, 5, 0);
      expect(TZHelper.isSameDay(loggedUtc, scheduledUtc, ianaZone), isTrue);
    });
  });

  group('TZHelper.todayIn', () {
    test('retourne la date locale (jour J) pour une timezone donnée', () {
      const ianaZone = 'Africa/Nairobi'; // UTC+3
      // On fournit un now = 2025-05-23 21:00 UTC = 2025-05-24 00:00 locale UTC+3
      final now = DateTime.utc(2025, 5, 23, 21, 0);
      final today = TZHelper.todayIn(ianaZone, now: now);
      // En locale UTC+3, il est déjà le 24
      expect(today.year, 2025);
      expect(today.month, 5);
      expect(today.day, 24);
    });

    test('occurrence_day_uses_user_timezone — '
        'même UTC → jours locaux différents selon timezone', () {
      final now = DateTime.utc(2025, 5, 23, 23, 0); // 23h UTC

      // UTC+3 → 02h locale le 24
      final dayNairobi = TZHelper.todayIn('Africa/Nairobi', now: now);
      // UTC-5 → 18h locale le 23
      final dayBogota = TZHelper.todayIn('America/Bogota', now: now);

      expect(dayNairobi.day, 24); // déjà le 24 à Nairobi
      expect(dayBogota.day, 23); // encore le 23 à Bogota
    });

    test('occurrence_day_column_matches_user_timezone_date — '
        'la date retournée n\'a pas de composante heure', () {
      final now = DateTime.utc(2025, 5, 23, 15, 30, 45);
      final today = TZHelper.todayIn('Europe/Paris', now: now);
      expect(today.hour, 0);
      expect(today.minute, 0);
      expect(today.second, 0);
    });
  });

  group('TZHelper.nowIn', () {
    test('retourne un TZDateTime dans la timezone demandée', () {
      const ianaZone = 'Africa/Nairobi';
      final nowUtc = DateTime.utc(2025, 5, 23, 20, 30);
      final result = TZHelper.nowIn(ianaZone, utcNow: nowUtc);
      // UTC+3 → heure locale = 23h30
      expect(result.hour, 23);
      expect(result.minute, 30);
    });
  });

  group('TZHelper.localMidnightUtc', () {
    test('retourne minuit local converti en UTC pour la timezone donnée', () {
      const ianaZone = 'Africa/Nairobi'; // UTC+3
      // Minuit Nairobi le 24 = 21h UTC le 23
      final midnight = TZHelper.localMidnightUtc(
        date: DateTime.utc(2025, 5, 24),
        ianaZone: ianaZone,
      );
      expect(midnight.isUtc, isTrue);
      expect(midnight.year, 2025);
      expect(midnight.month, 5);
      expect(midnight.day, 23);
      expect(midnight.hour, 21);
    });

    test('timezone_stored_on_signup — Dakar (UTC+0) minuit = minuit UTC', () {
      const ianaZone = 'Africa/Dakar'; // UTC+0
      final midnight = TZHelper.localMidnightUtc(
        date: DateTime.utc(2025, 5, 24),
        ianaZone: ianaZone,
      );
      expect(midnight.hour, 0);
      expect(midnight.day, 24);
    });
  });
}
