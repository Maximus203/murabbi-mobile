import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Mapper pur — convertit les rows `prayer_days` Supabase en `PrayerDay`
/// domain et inversement.
///
/// Mapping retenu (Q-19 close — migration `20260509000000_align_mobile_domain.sql`
/// a aligné l'enum SQL sur le domain) :
///
/// | SQL value   | Domain `PrayerStatus` |
/// |-------------|------------------------|
/// | `null`      | `pending`              |
/// | `'ontime'`  | `onTime`               |
/// | `'late'`    | `late`                 |
/// | `'missed'`  | `missed`               |
/// | `'makeup'`  | `makeup`               |
/// | `'skipped'` | (lecture) → throw `unknownStatus` (legacy V1, non couvert) |
///
/// Toute valeur SQL inconnue lève `PrayerFailure.unknownStatus` plutôt que
/// de faire un fallback silencieux.
class PrayerDayMapper {
  const PrayerDayMapper._();

  /// SQL row → entité domain.
  static PrayerDay fromRow(Map<String, dynamic> row) {
    final userIdRaw = row['user_id'];
    if (userIdRaw is! String || userIdRaw.isEmpty) {
      throw ArgumentError.value(
        userIdRaw,
        'user_id',
        'must be a non-empty UUID string',
      );
    }

    final dayRaw = row['date'];
    final DateTime date;
    if (dayRaw is DateTime) {
      date = dayRaw;
    } else if (dayRaw is String && dayRaw.isNotEmpty) {
      // Normalisation UTC : la colonne SQL est `date` (sans TZ). On force
      // l'UTC pour stabiliser l'égalité côté domain et éviter les drifts
      // selon le fuseau du device.
      final parsed = DateTime.parse(dayRaw);
      date = DateTime.utc(parsed.year, parsed.month, parsed.day);
    } else {
      throw ArgumentError.value(
        dayRaw,
        'date',
        'must be an ISO-8601 date String or a DateTime',
      );
    }

    return PrayerDay(
      userId: UserId(userIdRaw),
      date: date,
      fajr: _statusFromSql(row['fajr']),
      dhuhr: _statusFromSql(row['dhuhr']),
      asr: _statusFromSql(row['asr']),
      maghrib: _statusFromSql(row['maghrib']),
      isha: _statusFromSql(row['isha']),
    );
  }

  /// Entité domain → SQL row (clés alignées sur le schéma `prayer_days`).
  static Map<String, dynamic> toRow(PrayerDay day) {
    return {
      'user_id': day.userId.value,
      'date': _formatIsoDate(day.date),
      'fajr': _statusToSql(day.fajr),
      'dhuhr': _statusToSql(day.dhuhr),
      'asr': _statusToSql(day.asr),
      'maghrib': _statusToSql(day.maghrib),
      'isha': _statusToSql(day.isha),
    };
  }

  static PrayerStatus _statusFromSql(Object? raw) {
    if (raw == null) return PrayerStatus.pending;
    if (raw is! String) {
      throw PrayerFailure.malformedRow(
        message: 'Prayer status must be a String or null, got: $raw',
      );
    }
    switch (raw) {
      case 'ontime':
        return PrayerStatus.onTime;
      case 'late':
        return PrayerStatus.late;
      case 'missed':
        return PrayerStatus.missed;
      case 'makeup':
        return PrayerStatus.makeup;
      // 'skipped' (et tout autre) : non couvert côté domain.
      default:
        throw PrayerFailure.unknownStatus(
          message:
              'SQL prayer status "$raw" has no domain mapping. '
              'Expected one of: ontime, late, missed, makeup, or null.',
        );
    }
  }

  static String? _statusToSql(PrayerStatus status) {
    switch (status) {
      case PrayerStatus.pending:
        return null;
      case PrayerStatus.onTime:
        return 'ontime';
      case PrayerStatus.late:
        return 'late';
      case PrayerStatus.missed:
        return 'missed';
      case PrayerStatus.makeup:
        return 'makeup';
    }
  }

  /// Format ISO-8601 date (YYYY-MM-DD) sans composante horaire — la colonne
  /// SQL est `date`, pas `timestamptz`.
  static String _formatIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
