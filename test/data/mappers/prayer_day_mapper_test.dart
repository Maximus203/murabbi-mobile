import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/prayer_day_mapper.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Tests du mapper Supabase ↔ domain pour `prayer_days` (Q-19).
///
/// Mapping retenu (cf. `docs/questions/Q-19-salat-status-mapping-domain-vs-sql.md`) :
///   null      ↔ pending
///   'ontime'  ↔ onTime
///   'late'    ↔ late
///   'missed'  ↔ missed
///   'skipped' (lecture)   → throw PrayerFailure.unknownStatus (fail-fast)
///   makeup    (écriture)  → throw PrayerFailure.unsupportedStatus
void main() {
  const userId = '11111111-1111-1111-1111-111111111111';

  Map<String, dynamic> validRow({
    Object? fajr,
    Object? dhuhr,
    Object? asr,
    Object? maghrib,
    Object? isha,
    String day = '2026-05-09',
  }) => {
    'user_id': userId,
    'day': day,
    'fajr': fajr,
    'dhuhr': dhuhr,
    'asr': asr,
    'maghrib': maghrib,
    'isha': isha,
  };

  group('PrayerDayMapper.fromRow', () {
    test('null SQL value maps to PrayerStatus.pending', () {
      final row = validRow();
      final entity = PrayerDayMapper.fromRow(row);

      expect(entity.userId, UserId(userId));
      expect(entity.date, DateTime.utc(2026, 5, 9));
      expect(entity.fajr, PrayerStatus.pending);
      expect(entity.dhuhr, PrayerStatus.pending);
      expect(entity.asr, PrayerStatus.pending);
      expect(entity.maghrib, PrayerStatus.pending);
      expect(entity.isha, PrayerStatus.pending);
    });

    test('"ontime" maps to PrayerStatus.onTime', () {
      final row = validRow(fajr: 'ontime');
      final entity = PrayerDayMapper.fromRow(row);
      expect(entity.fajr, PrayerStatus.onTime);
    });

    test('"late" maps to PrayerStatus.late', () {
      final row = validRow(dhuhr: 'late');
      expect(PrayerDayMapper.fromRow(row).dhuhr, PrayerStatus.late);
    });

    test('"missed" maps to PrayerStatus.missed', () {
      final row = validRow(asr: 'missed');
      expect(PrayerDayMapper.fromRow(row).asr, PrayerStatus.missed);
    });

    test('all 5 prayers populated independently', () {
      final row = validRow(
        fajr: 'ontime',
        dhuhr: 'late',
        asr: 'missed',
        maghrib: null,
        isha: 'ontime',
      );
      final entity = PrayerDayMapper.fromRow(row);
      expect(entity.fajr, PrayerStatus.onTime);
      expect(entity.dhuhr, PrayerStatus.late);
      expect(entity.asr, PrayerStatus.missed);
      expect(entity.maghrib, PrayerStatus.pending);
      expect(entity.isha, PrayerStatus.onTime);
    });

    test(
      '"skipped" SQL value throws unknownStatus failure (Q-19 fail-fast)',
      () {
        final row = validRow(fajr: 'skipped');
        expect(
          () => PrayerDayMapper.fromRow(row),
          throwsA(isA<UnknownPrayerStatusFailure>()),
        );
      },
    );

    test('unrecognized SQL value throws unknownStatus failure', () {
      final row = validRow(maghrib: 'wat');
      expect(
        () => PrayerDayMapper.fromRow(row),
        throwsA(isA<UnknownPrayerStatusFailure>()),
      );
    });

    test('missing user_id throws ArgumentError', () {
      final row = validRow()..remove('user_id');
      expect(() => PrayerDayMapper.fromRow(row), throwsA(isA<ArgumentError>()));
    });

    test('empty user_id throws ArgumentError', () {
      final row = validRow();
      row['user_id'] = '';
      expect(() => PrayerDayMapper.fromRow(row), throwsA(isA<ArgumentError>()));
    });

    test('missing day throws ArgumentError', () {
      final row = validRow()..remove('day');
      expect(() => PrayerDayMapper.fromRow(row), throwsA(isA<ArgumentError>()));
    });

    test('non-String non-null status throws malformedRow failure', () {
      final row = validRow();
      row['fajr'] = 42; // int — neither String nor null
      expect(
        () => PrayerDayMapper.fromRow(row),
        throwsA(isA<PrayerMalformedRowFailure>()),
      );
    });

    test('day already a DateTime is accepted', () {
      final row = validRow();
      row['day'] = DateTime.utc(2026, 5, 9);
      final entity = PrayerDayMapper.fromRow(row);
      expect(entity.date, DateTime.utc(2026, 5, 9));
    });
  });

  group('PrayerDayMapper.toRow', () {
    PrayerDay buildDay({
      PrayerStatus fajr = PrayerStatus.pending,
      PrayerStatus dhuhr = PrayerStatus.pending,
      PrayerStatus asr = PrayerStatus.pending,
      PrayerStatus maghrib = PrayerStatus.pending,
      PrayerStatus isha = PrayerStatus.pending,
    }) => PrayerDay(
      userId: UserId(userId),
      date: DateTime.utc(2026, 5, 9),
      fajr: fajr,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );

    test('pending maps to null in SQL row', () {
      final row = PrayerDayMapper.toRow(buildDay());
      expect(row['fajr'], isNull);
      expect(row['dhuhr'], isNull);
      expect(row['asr'], isNull);
      expect(row['maghrib'], isNull);
      expect(row['isha'], isNull);
    });

    test('onTime maps to "ontime" in SQL row', () {
      final row = PrayerDayMapper.toRow(buildDay(fajr: PrayerStatus.onTime));
      expect(row['fajr'], 'ontime');
    });

    test('late maps to "late"', () {
      final row = PrayerDayMapper.toRow(buildDay(dhuhr: PrayerStatus.late));
      expect(row['dhuhr'], 'late');
    });

    test('missed maps to "missed"', () {
      final row = PrayerDayMapper.toRow(buildDay(asr: PrayerStatus.missed));
      expect(row['asr'], 'missed');
    });

    test('makeup throws unsupportedStatus failure (Q-19 — schema gap)', () {
      expect(
        () => PrayerDayMapper.toRow(buildDay(maghrib: PrayerStatus.makeup)),
        throwsA(isA<UnsupportedPrayerStatusFailure>()),
      );
    });

    test('userId and date serialized correctly', () {
      final row = PrayerDayMapper.toRow(buildDay());
      expect(row['user_id'], userId);
      // ISO date YYYY-MM-DD (no time) — SQL "date" column.
      expect(row['day'], '2026-05-09');
    });
  });

  group('Round-trip', () {
    test('SQL → domain → SQL preserves all 5 prayer statuses', () {
      final original = {
        'user_id': userId,
        'day': '2026-05-09',
        'fajr': 'ontime',
        'dhuhr': 'late',
        'asr': 'missed',
        'maghrib': null,
        'isha': 'ontime',
      };
      final entity = PrayerDayMapper.fromRow(original);
      final roundtrip = PrayerDayMapper.toRow(entity);

      expect(roundtrip['user_id'], original['user_id']);
      expect(roundtrip['day'], original['day']);
      expect(roundtrip['fajr'], original['fajr']);
      expect(roundtrip['dhuhr'], original['dhuhr']);
      expect(roundtrip['asr'], original['asr']);
      expect(roundtrip['maghrib'], original['maghrib']);
      expect(roundtrip['isha'], original['isha']);
    });

    test('domain → SQL → domain preserves equality', () {
      final original = PrayerDay(
        userId: UserId(userId),
        date: DateTime.utc(2026, 5, 9),
        fajr: PrayerStatus.onTime,
        dhuhr: PrayerStatus.late,
        asr: PrayerStatus.missed,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.onTime,
      );
      final row = PrayerDayMapper.toRow(original);
      // toRow ne contient pas user_id/day si on les sépare ; on s'assure
      // qu'ils sont bien là pour permettre l'aller-retour complet.
      final roundtrip = PrayerDayMapper.fromRow(row);
      expect(roundtrip, original);
    });
  });
}
