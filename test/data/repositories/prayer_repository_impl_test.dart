import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/datasources/salat_data_source.dart';
import 'package:murabbi_mobile/data/repositories/prayer_repository_impl.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class _MockDataSource extends Mock implements SalatDataSource {}

void main() {
  late _MockDataSource ds;
  late PrayerRepositoryImpl repo;

  const userIdValue = '11111111-1111-1111-1111-111111111111';
  final today = DateTime.utc(2026, 5, 9);

  Map<String, dynamic> rowFor({
    String userId = userIdValue,
    String day = '2026-05-09',
    Object? fajr,
    Object? dhuhr,
    Object? asr,
    Object? maghrib,
    Object? isha,
  }) => {
    'user_id': userId,
    'day': day,
    'fajr': fajr,
    'dhuhr': dhuhr,
    'asr': asr,
    'maghrib': maghrib,
    'isha': isha,
  };

  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    ds = _MockDataSource();
    repo = PrayerRepositoryImpl(ds);
  });

  group('getTodayPrayers', () {
    test('returns a fully-pending PrayerDay when no row exists yet', () async {
      when(
        () => ds.getPrayerDay(
          userId: userIdValue,
          day: any(named: 'day'),
        ),
      ).thenAnswer((_) async => null);

      final day = await repo.getTodayPrayers(UserId(userIdValue));

      expect(day.userId, UserId(userIdValue));
      expect(day.fajr, PrayerStatus.pending);
      expect(day.dhuhr, PrayerStatus.pending);
      expect(day.asr, PrayerStatus.pending);
      expect(day.maghrib, PrayerStatus.pending);
      expect(day.isha, PrayerStatus.pending);
    });

    test('maps the row when a partial day exists', () async {
      when(
        () => ds.getPrayerDay(
          userId: userIdValue,
          day: any(named: 'day'),
        ),
      ).thenAnswer((_) async => rowFor(fajr: 'ontime', dhuhr: 'late'));

      final day = await repo.getTodayPrayers(UserId(userIdValue));
      expect(day.fajr, PrayerStatus.onTime);
      expect(day.dhuhr, PrayerStatus.late);
      expect(day.asr, PrayerStatus.pending);
    });
  });

  group('markPrayer', () {
    test(
      'upserts a row with the new fajr status, merging existing day',
      () async {
        when(
          () => ds.getPrayerDay(userId: userIdValue, day: '2026-05-09'),
        ).thenAnswer((_) async => rowFor(dhuhr: 'late'));
        when(() => ds.upsertPrayerDay(any())).thenAnswer((_) async {});

        await repo.markPrayer(
          userId: UserId(userIdValue),
          date: today,
          prayerName: 'fajr',
          status: PrayerStatus.onTime,
        );

        final captured =
            verify(() => ds.upsertPrayerDay(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['user_id'], userIdValue);
        expect(captured['day'], '2026-05-09');
        expect(captured['fajr'], 'ontime');
        // pre-existing dhuhr is preserved
        expect(captured['dhuhr'], 'late');
      },
    );

    test('updates dhuhr while preserving other prayers', () async {
      when(
        () => ds.getPrayerDay(userId: userIdValue, day: '2026-05-09'),
      ).thenAnswer((_) async => rowFor(fajr: 'ontime'));
      when(() => ds.upsertPrayerDay(any())).thenAnswer((_) async {});

      await repo.markPrayer(
        userId: UserId(userIdValue),
        date: today,
        prayerName: 'dhuhr',
        status: PrayerStatus.late,
      );

      final captured =
          verify(() => ds.upsertPrayerDay(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['fajr'], 'ontime');
      expect(captured['dhuhr'], 'late');
    });

    test('updates asr while preserving other prayers', () async {
      when(
        () => ds.getPrayerDay(userId: userIdValue, day: '2026-05-09'),
      ).thenAnswer((_) async => null);
      when(() => ds.upsertPrayerDay(any())).thenAnswer((_) async {});

      await repo.markPrayer(
        userId: UserId(userIdValue),
        date: today,
        prayerName: 'asr',
        status: PrayerStatus.missed,
      );

      final captured =
          verify(() => ds.upsertPrayerDay(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['asr'], 'missed');
    });

    test('updates maghrib', () async {
      when(
        () => ds.getPrayerDay(userId: userIdValue, day: '2026-05-09'),
      ).thenAnswer((_) async => null);
      when(() => ds.upsertPrayerDay(any())).thenAnswer((_) async {});
      await repo.markPrayer(
        userId: UserId(userIdValue),
        date: today,
        prayerName: 'maghrib',
        status: PrayerStatus.onTime,
      );
      final captured =
          verify(() => ds.upsertPrayerDay(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['maghrib'], 'ontime');
    });

    test('updates isha', () async {
      when(
        () => ds.getPrayerDay(userId: userIdValue, day: '2026-05-09'),
      ).thenAnswer((_) async => null);
      when(() => ds.upsertPrayerDay(any())).thenAnswer((_) async {});
      await repo.markPrayer(
        userId: UserId(userIdValue),
        date: today,
        prayerName: 'isha',
        status: PrayerStatus.late,
      );
      final captured =
          verify(() => ds.upsertPrayerDay(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['isha'], 'late');
    });

    test('rejects an unknown prayer name', () async {
      expect(
        () => repo.markPrayer(
          userId: UserId(userIdValue),
          date: today,
          prayerName: 'tahajjud',
          status: PrayerStatus.onTime,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('translates network errors to PrayerFailure.network', () async {
      when(
        () => ds.getPrayerDay(
          userId: any(named: 'userId'),
          day: any(named: 'day'),
        ),
      ).thenThrow(Exception('SocketException: Failed host lookup'));

      expect(
        () => repo.markPrayer(
          userId: UserId(userIdValue),
          date: today,
          prayerName: 'fajr',
          status: PrayerStatus.onTime,
        ),
        throwsA(isA<PrayerNetworkFailure>()),
      );
    });

    test('translates PostgrestException to PrayerFailure.database', () async {
      when(
        () => ds.getPrayerDay(
          userId: any(named: 'userId'),
          day: any(named: 'day'),
        ),
      ).thenAnswer((_) async => null);
      when(() => ds.upsertPrayerDay(any())).thenThrow(
        const sb.PostgrestException(message: 'duplicate key', code: '23505'),
      );

      expect(
        () => repo.markPrayer(
          userId: UserId(userIdValue),
          date: today,
          prayerName: 'fajr',
          status: PrayerStatus.onTime,
        ),
        throwsA(isA<PrayerDatabaseFailure>()),
      );
    });

    test(
      'lets PrayerFailure.unsupportedStatus bubble up unchanged for makeup',
      () async {
        when(
          () => ds.getPrayerDay(
            userId: any(named: 'userId'),
            day: any(named: 'day'),
          ),
        ).thenAnswer((_) async => null);

        expect(
          () => repo.markPrayer(
            userId: UserId(userIdValue),
            date: today,
            prayerName: 'fajr',
            status: PrayerStatus.makeup,
          ),
          throwsA(isA<UnsupportedPrayerStatusFailure>()),
        );
      },
    );
  });

  group('getPrayerHistory', () {
    test('forwards the date range and maps all rows', () async {
      final from = DateTime.utc(2026, 5, 1);
      final to = DateTime.utc(2026, 5, 9);

      when(
        () => ds.getPrayerDaysRange(
          userId: userIdValue,
          from: '2026-05-01',
          to: '2026-05-09',
        ),
      ).thenAnswer(
        (_) async => [
          rowFor(day: '2026-05-01', fajr: 'ontime'),
          rowFor(day: '2026-05-02', fajr: 'late', dhuhr: 'missed'),
        ],
      );

      final list = await repo.getPrayerHistory(
        userId: UserId(userIdValue),
        from: from,
        to: to,
      );

      expect(list, hasLength(2));
      expect(list[0].fajr, PrayerStatus.onTime);
      expect(list[1].fajr, PrayerStatus.late);
      expect(list[1].dhuhr, PrayerStatus.missed);
    });

    test('translates unrecognized errors to PrayerFailure.unknown', () async {
      when(
        () => ds.getPrayerDaysRange(
          userId: any(named: 'userId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenThrow(StateError('unexpected'));

      expect(
        () => repo.getPrayerHistory(
          userId: UserId(userIdValue),
          from: DateTime.utc(2026, 5, 1),
          to: DateTime.utc(2026, 5, 9),
        ),
        throwsA(isA<UnknownPrayerFailure>()),
      );
    });
  });
}
