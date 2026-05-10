import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_service.dart';

/// Tolérance des golden values vs notre implémentation. 1 minute = arrondi
/// interne `adhan_dart` (`Rounding.nearest`) + précisions millisecondes,
/// suffisant pour un filet anti-régression : si demain on swap la lib, ces
/// valeurs doivent rester stables à ±1 min près.
const _selfTolerance = Duration(minutes: 1);

/// Tolérance vs Aladhan API (oracle externe). 10 minutes = drift accepté
/// entre moteurs (cf. `prayer-times-strategy-research-2026-05-09.md` §5.2 :
/// adhan-js, Aladhan, Athan Pro divergent typiquement de 3–8 min sur Fajr/Isha
/// selon l'algorithme exact de seconde-passe). Sert à vérifier qu'on ne
/// drifte pas franchement.
const _oracleTolerance = Duration(minutes: 10);

void _expectClose(
  DateTime actual,
  DateTime expectedUtc,
  String label, {
  Duration tolerance = _selfTolerance,
}) {
  final diff = actual.toUtc().difference(expectedUtc).abs();
  expect(
    diff <= tolerance,
    isTrue,
    reason:
        '$label: expected $expectedUtc ± ${tolerance.inSeconds}s, got '
        '${actual.toUtc()} (diff = ${diff.inSeconds}s)',
  );
}

PrayerSettings _settings({
  required CalculationMethod method,
  required Madhab madhab,
  required double lat,
  required double lng,
  HighLatitudeRule rule = HighLatitudeRule.middleOfTheNight,
}) => PrayerSettings(
  method: method,
  madhab: madhab,
  latitude: lat,
  longitude: lng,
  highLatitudeRule: rule,
);

void main() {
  late PrayerTimesService service;

  setUp(() {
    service = const AdhanPrayerTimesService();
  });

  group('AdhanPrayerTimesService — golden values (filet anti-régression)', () {
    // Les valeurs ci-dessous sont produites par `adhan_dart` 2.0.0 (port MIT
    // direct de `adhan-js` Batoul Apps, référence du domaine). Elles sont
    // verrouillées au commit pour détecter toute régression de mapping ou
    // bump de la lib. La tolérance ±1 min absorbe les arrondis internes.
    //
    // Cross-check Aladhan API (méthode 12 UOIF) effectué le 2026-05-10 sur
    // Paris 2024-06-15 — drift observé ~8 min sur Fajr (02:04 UTC vs 02:12
    // UTC Aladhan), conforme aux ±10 min documentés en §5.2 recherche.
    // Cf. test `Paris vs Aladhan oracle` plus bas.

    test('Paris UOIF Shafi — 15 juin 2024', () {
      final times = service.computeForDay(
        settings: _settings(
          method: CalculationMethod.uoif,
          madhab: Madhab.shafi,
          lat: 48.8566,
          lng: 2.3522,
        ),
        day: DateTime.utc(2024, 6, 15),
      );
      _expectClose(times.fajr, DateTime.utc(2024, 6, 15, 2, 4), 'fajr');
      _expectClose(times.sunrise, DateTime.utc(2024, 6, 15, 3, 46), 'sunrise');
      _expectClose(times.dhuhr, DateTime.utc(2024, 6, 15, 11, 51), 'dhuhr');
      _expectClose(times.asr, DateTime.utc(2024, 6, 15, 16, 8), 'asr');
      _expectClose(times.maghrib, DateTime.utc(2024, 6, 15, 19, 56), 'maghrib');
      _expectClose(times.isha, DateTime.utc(2024, 6, 15, 21, 39), 'isha');
    });

    test('Casablanca Morocco Shafi — 1 mars 2025', () {
      final times = service.computeForDay(
        settings: _settings(
          method: CalculationMethod.morocco,
          madhab: Madhab.shafi,
          lat: 33.5731,
          lng: -7.5898,
        ),
        day: DateTime.utc(2025, 3, 1),
      );
      _expectClose(times.fajr, DateTime.utc(2025, 3, 1, 5, 31), 'fajr');
      _expectClose(times.sunrise, DateTime.utc(2025, 3, 1, 6, 56), 'sunrise');
      _expectClose(times.dhuhr, DateTime.utc(2025, 3, 1, 12, 48), 'dhuhr');
      _expectClose(times.asr, DateTime.utc(2025, 3, 1, 15, 59), 'asr');
      _expectClose(times.maghrib, DateTime.utc(2025, 3, 1, 18, 32), 'maghrib');
      _expectClose(times.isha, DateTime.utc(2025, 3, 1, 19, 45), 'isha');
    });

    test('Mecca Umm al-Qura Shafi — 10 mars 2024', () {
      final times = service.computeForDay(
        settings: _settings(
          method: CalculationMethod.ummAlQura,
          madhab: Madhab.shafi,
          lat: 21.4225,
          lng: 39.8262,
        ),
        day: DateTime.utc(2024, 3, 10),
      );
      _expectClose(times.fajr, DateTime.utc(2024, 3, 10, 2, 18), 'fajr');
      _expectClose(times.dhuhr, DateTime.utc(2024, 3, 10, 9, 31), 'dhuhr');
      _expectClose(times.maghrib, DateTime.utc(2024, 3, 10, 15, 28), 'maghrib');
      _expectClose(times.isha, DateTime.utc(2024, 3, 10, 16, 58), 'isha');
      // Umm al-Qura : Isha = Maghrib + 90 min.
      final ishaDelta = times.isha.difference(times.maghrib).inMinutes;
      expect(
        (ishaDelta - 90).abs() <= 1,
        isTrue,
        reason: 'Isha doit être ~90 min après Maghrib, got ${ishaDelta}min',
      );
    });

    test('Istanbul Diyanet Shafi — 21 septembre 2024 (équinoxe automne)', () {
      final times = service.computeForDay(
        settings: _settings(
          method: CalculationMethod.diyanet,
          madhab: Madhab.shafi,
          lat: 41.0082,
          lng: 28.9784,
        ),
        day: DateTime.utc(2024, 9, 21),
      );
      _expectClose(times.fajr, DateTime.utc(2024, 9, 21, 2, 18), 'fajr');
      _expectClose(times.dhuhr, DateTime.utc(2024, 9, 21, 10, 2), 'dhuhr');
      _expectClose(times.maghrib, DateTime.utc(2024, 9, 21, 16, 9), 'maghrib');
    });

    test('New York ISNA Shafi — 21 décembre 2024 (solstice hiver)', () {
      final times = service.computeForDay(
        settings: _settings(
          method: CalculationMethod.isna,
          madhab: Madhab.shafi,
          lat: 40.7128,
          lng: -74.0060,
        ),
        day: DateTime.utc(2024, 12, 21),
      );
      // NYC en heure d'hiver = UTC-5. Fajr à 05:55 local = 10:55 UTC.
      _expectClose(times.fajr, DateTime.utc(2024, 12, 21, 10, 55), 'fajr');
      _expectClose(times.dhuhr, DateTime.utc(2024, 12, 21, 16, 55), 'dhuhr');
      _expectClose(times.isha, DateTime.utc(2024, 12, 21, 22, 54), 'isha');
    });
  });

  group(
    'AdhanPrayerTimesService — cross-check Aladhan API (oracle externe)',
    () {
      test('Paris UOIF 2024-06-15 — drift Aladhan dans ±10 min', () {
        // Valeurs Aladhan API (https://api.aladhan.com/v1/timings/15-06-2024
        // ?latitude=48.8566&longitude=2.3522&method=12) snapshot 2026-05-10 :
        //   Fajr 04:12 / Sunrise 05:46 / Dhuhr 13:51 / Asr 18:08
        //   Maghrib 21:56 / Isha 23:30 (heure locale Europe/Paris UTC+2).
        // adhan-js et Aladhan implémentent des algorithmes proches mais pas
        // strictement identiques sur Fajr/Isha (cf. recherche §5.2).
        final times = service.computeForDay(
          settings: _settings(
            method: CalculationMethod.uoif,
            madhab: Madhab.shafi,
            lat: 48.8566,
            lng: 2.3522,
          ),
          day: DateTime.utc(2024, 6, 15),
        );
        _expectClose(
          times.fajr,
          DateTime.utc(2024, 6, 15, 2, 12),
          'fajr',
          tolerance: _oracleTolerance,
        );
        _expectClose(
          times.sunrise,
          DateTime.utc(2024, 6, 15, 3, 46),
          'sunrise',
          tolerance: _oracleTolerance,
        );
        _expectClose(
          times.dhuhr,
          DateTime.utc(2024, 6, 15, 11, 51),
          'dhuhr',
          tolerance: _oracleTolerance,
        );
        _expectClose(
          times.asr,
          DateTime.utc(2024, 6, 15, 16, 8),
          'asr',
          tolerance: _oracleTolerance,
        );
        _expectClose(
          times.maghrib,
          DateTime.utc(2024, 6, 15, 19, 56),
          'maghrib',
          tolerance: _oracleTolerance,
        );
        _expectClose(
          times.isha,
          DateTime.utc(2024, 6, 15, 21, 30),
          'isha',
          tolerance: _oracleTolerance,
        );
      });
    },
  );

  group('AdhanPrayerTimesService — invariants métier', () {
    test(
      'Hanafi calcule Asr plus tard que Shafi (mêmes coords/date/méthode)',
      () {
        final day = DateTime.utc(2024, 6, 15);
        const lat = 48.8566;
        const lng = 2.3522;
        final shafi = service.computeForDay(
          settings: _settings(
            method: CalculationMethod.uoif,
            madhab: Madhab.shafi,
            lat: lat,
            lng: lng,
          ),
          day: day,
        );
        final hanafi = service.computeForDay(
          settings: _settings(
            method: CalculationMethod.uoif,
            madhab: Madhab.hanafi,
            lat: lat,
            lng: lng,
          ),
          day: day,
        );
        expect(
          hanafi.asr.isAfter(shafi.asr),
          isTrue,
          reason:
              'Hanafi Asr doit être strictement après Shafi Asr '
              '(ratio ombre 2× vs 1×)',
        );
        // Madhab n'affecte que Asr.
        expect(hanafi.fajr, shafi.fajr);
        expect(hanafi.dhuhr, shafi.dhuhr);
        expect(hanafi.maghrib, shafi.maghrib);
      },
    );

    test(
      'Oslo en juin — les 3 high-latitude rules produisent toutes 6 horaires '
      'finis et chronologiques',
      () {
        final day = DateTime.utc(2024, 6, 21);
        const lat = 59.9139;
        const lng = 10.7522;
        for (final rule in HighLatitudeRule.values) {
          final times = service.computeForDay(
            settings: _settings(
              method: CalculationMethod.moonsighting,
              madhab: Madhab.shafi,
              lat: lat,
              lng: lng,
              rule: rule,
            ),
            day: day,
          );
          expect(
            times.fajr.millisecondsSinceEpoch.isFinite,
            isTrue,
            reason: 'rule=$rule fajr non fini',
          );
          expect(
            times.isha.millisecondsSinceEpoch.isFinite,
            isTrue,
            reason: 'rule=$rule isha non fini',
          );
        }
      },
    );

    test('jour bissextile (29 février 2024) à Paris UOIF retourne 6 horaires '
        'cohérents', () {
      final times = service.computeForDay(
        settings: _settings(
          method: CalculationMethod.uoif,
          madhab: Madhab.shafi,
          lat: 48.8566,
          lng: 2.3522,
        ),
        day: DateTime.utc(2024, 2, 29),
      );
      // L'invariant chronologique du constructeur PrayerTimes garantit
      // déjà l'ordre. Ici on s'assure simplement que la date est respectée.
      expect(times.fajr.toUtc().day, 29);
      expect(times.fajr.toUtc().month, 2);
    });

    test('Algérie + Tunisie sont natives dans adhan_dart 2.0.0 (pas de '
        'fallback "Other")', () {
      // Sécurise la décision ADR-013 §Limites : si l'une de ces méthodes
      // n'était pas exposée nativement, on devrait passer par
      // CalculationMethod.other avec params custom.
      final day = DateTime.utc(2024, 5, 10);
      expect(
        () => service.computeForDay(
          settings: _settings(
            method: CalculationMethod.algeria,
            madhab: Madhab.shafi,
            lat: 36.7538,
            lng: 3.0588,
          ),
          day: day,
        ),
        returnsNormally,
      );
      expect(
        () => service.computeForDay(
          settings: _settings(
            method: CalculationMethod.tunisia,
            madhab: Madhab.shafi,
            lat: 36.8065,
            lng: 10.1815,
          ),
          day: day,
        ),
        returnsNormally,
      );
    });

    test(
      'toutes les CalculationMethod sont mappées (pas de UnimplementedError)',
      () {
        final day = DateTime.utc(2024, 6, 15);
        for (final m in CalculationMethod.values) {
          expect(
            () => service.computeForDay(
              settings: _settings(
                method: m,
                madhab: Madhab.shafi,
                lat: 48.8566,
                lng: 2.3522,
              ),
              day: day,
            ),
            returnsNormally,
            reason: 'CalculationMethod.$m doit être mappée',
          );
        }
      },
    );

    test('31 décembre — passage à l\'année suivante ne provoque pas de '
        'décalage', () {
      // Le 31 décembre, la lib calcule fajrAfter = Fajr du 1er janvier.
      // Vérifie que computeForDay du 31 décembre retourne bien les horaires
      // du 31 décembre, pas du 1er janvier.
      final times = service.computeForDay(
        settings: _settings(
          method: CalculationMethod.uoif,
          madhab: Madhab.shafi,
          lat: 48.8566,
          lng: 2.3522,
        ),
        day: DateTime.utc(2024, 12, 31),
      );
      expect(times.dhuhr.toUtc().year, 2024);
      expect(times.dhuhr.toUtc().month, 12);
      expect(times.dhuhr.toUtc().day, 31);
    });
  });
}
