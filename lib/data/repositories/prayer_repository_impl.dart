import 'package:murabbi_mobile/data/datasources/salat_data_source.dart';
import 'package:murabbi_mobile/data/mappers/prayer_day_mapper.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Implémentation du `PrayerRepository` adossée à un `SalatDataSource`.
///
/// Responsabilités :
///   1. Cadrer les dates au format ISO `YYYY-MM-DD` attendu par le datasource
///      (la colonne SQL est `date`, pas `timestamptz`).
///   2. Construire/parser les rows via `PrayerDayMapper`.
///   3. Pour `markPrayer` : merge avec la row existante pour ne pas écraser
///      les autres prières de la journée (l'upsert remplace toute la ligne).
///   4. Traduire les exceptions natives Supabase en `PrayerFailure` typées.
///      Le pattern suit `AuthRepositoryImpl._guard / _translate`.
class PrayerRepositoryImpl implements PrayerRepository {
  static const _allowedPrayers = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};

  final SalatDataSource _ds;

  const PrayerRepositoryImpl(this._ds);

  @override
  Future<PrayerDay> getTodayPrayers(UserId userId) => _guard(() async {
    final today = DateTime.now().toUtc();
    final iso = _formatIsoDate(today);
    final row = await _ds.getPrayerDay(userId: userId.value, day: iso);
    if (row == null) {
      // Aucun enregistrement pour aujourd'hui : tous les statuts sont
      // `pending` (= "non encore loggée").
      return PrayerDay(
        userId: userId,
        date: DateTime.utc(today.year, today.month, today.day),
        fajr: PrayerStatus.pending,
        dhuhr: PrayerStatus.pending,
        asr: PrayerStatus.pending,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.pending,
      );
    }
    return PrayerDayMapper.fromRow(row);
  });

  @override
  Future<void> markPrayer({
    required UserId userId,
    required DateTime date,
    required String prayerName,
    required PrayerStatus status,
  }) => _guard(() async {
    if (!_allowedPrayers.contains(prayerName)) {
      throw ArgumentError.value(
        prayerName,
        'prayerName',
        'must be one of $_allowedPrayers',
      );
    }
    final iso = _formatIsoDate(date);
    final existing = await _ds.getPrayerDay(userId: userId.value, day: iso);

    // Construit la row à upserter en fusionnant avec l'existant pour ne pas
    // écraser les autres prières.
    PrayerDay merged;
    if (existing == null) {
      merged = PrayerDay(
        userId: userId,
        date: DateTime.utc(date.year, date.month, date.day),
        fajr: PrayerStatus.pending,
        dhuhr: PrayerStatus.pending,
        asr: PrayerStatus.pending,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.pending,
      );
    } else {
      merged = PrayerDayMapper.fromRow(existing);
    }
    merged = _withPrayer(merged, prayerName, status);

    final row = PrayerDayMapper.toRow(merged);
    await _ds.upsertPrayerDay(row);
  });

  @override
  Future<List<PrayerDay>> getPrayerHistory({
    required UserId userId,
    required DateTime from,
    required DateTime to,
  }) => _guard(() async {
    final rows = await _ds.getPrayerDaysRange(
      userId: userId.value,
      from: _formatIsoDate(from),
      to: _formatIsoDate(to),
    );
    return rows.map(PrayerDayMapper.fromRow).toList();
  });

  PrayerDay _withPrayer(PrayerDay day, String name, PrayerStatus status) {
    switch (name) {
      case 'fajr':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: status,
          dhuhr: day.dhuhr,
          asr: day.asr,
          maghrib: day.maghrib,
          isha: day.isha,
        );
      case 'dhuhr':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: status,
          asr: day.asr,
          maghrib: day.maghrib,
          isha: day.isha,
        );
      case 'asr':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: day.dhuhr,
          asr: status,
          maghrib: day.maghrib,
          isha: day.isha,
        );
      case 'maghrib':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: day.dhuhr,
          asr: day.asr,
          maghrib: status,
          isha: day.isha,
        );
      case 'isha':
        return PrayerDay(
          userId: day.userId,
          date: day.date,
          fajr: day.fajr,
          dhuhr: day.dhuhr,
          asr: day.asr,
          maghrib: day.maghrib,
          isha: status,
        );
      default:
        // Garde-fou — `markPrayer` valide en amont, mais on reste explicite.
        throw ArgumentError.value(name, 'prayerName');
    }
  }

  String _formatIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // Traduit les exceptions natives en `PrayerFailure`. Calé sur le pattern
  // `AuthRepositoryImpl._guard`. Les `PrayerFailure` (incluant celles levées
  // par le mapper) et les `ArgumentError` (validation interne) sont
  // re-propagées telles quelles.
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PrayerFailure {
      rethrow;
    } on ArgumentError {
      rethrow;
    } on sb.PostgrestException catch (e) {
      throw PrayerFailure.database(message: '${e.code ?? ''} ${e.message}');
    } catch (e) {
      throw _translate(e);
    }
  }

  PrayerFailure _translate(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('rate_limit') ||
        msg.contains('rate limit')) {
      return PrayerFailure.network(message: error.toString());
    }
    return PrayerFailure.unknown(message: error.toString());
  }
}
