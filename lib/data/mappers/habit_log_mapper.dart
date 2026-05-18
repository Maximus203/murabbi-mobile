import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';

/// Mapper pur — convertit les rows `habit_logs` Supabase en [HabitLog] domain
/// et inversement.
///
/// Schéma `habit_logs` consommé (v1.5, spec § 2.3) :
///   `habit_id, date, status, actual_value, target_reached,
///    subtasks_completed, duration_seconds, opened_at, logged_at`.
///
/// Mapping enum `status` :
///   `'ontime'` → onTime · `'late'` → late · `'missed'` → missed.
class HabitLogMapper {
  const HabitLogMapper._();

  /// SQL row → entité domain.
  static HabitLog fromRow(Map<String, dynamic> row) {
    final durationSeconds = row['duration_seconds'] as int?;
    final subtasksRaw = row['subtasks_completed'] as List<dynamic>?;

    return HabitLog(
      habitId: HabitId(row['habit_id'] as String),
      date: _parseDate(row['date']),
      status: _statusFromSql(row['status'] as String),
      actualValue: row['actual_value'] as int?,
      targetReached: row['target_reached'] as bool?,
      subtasksCompleted:
          subtasksRaw
              ?.map((e) => HabitSubtaskId(e as String))
              .toList(growable: false) ??
          const [],
      duration: durationSeconds == null
          ? null
          : Duration(seconds: durationSeconds),
      openedAt: _parseTimestamp(row['opened_at']),
      loggedAt: _parseTimestamp(row['logged_at']),
    );
  }

  /// Entité domain → SQL row.
  static Map<String, dynamic> toRow(HabitLog log) {
    return {
      'habit_id': log.habitId.value,
      'date': _formatIsoDate(log.date),
      'status': _statusToSql(log.status),
      'actual_value': log.actualValue,
      'target_reached': log.targetReached,
      'subtasks_completed': log.subtasksCompleted
          .map((id) => id.value)
          .toList(growable: false),
      'duration_seconds': log.duration?.inSeconds,
      'opened_at': log.openedAt?.toUtc().toIso8601String(),
      'logged_at': log.loggedAt?.toUtc().toIso8601String(),
    };
  }

  static HabitLogStatus _statusFromSql(String raw) {
    switch (raw) {
      case 'ontime':
        return HabitLogStatus.onTime;
      case 'late':
        return HabitLogStatus.late;
      case 'missed':
        return HabitLogStatus.missed;
      default:
        throw ArgumentError.value(
          raw,
          'status',
          'Unknown HabitLog status — expected ontime, late or missed',
        );
    }
  }

  static String _statusToSql(HabitLogStatus status) {
    switch (status) {
      case HabitLogStatus.onTime:
        return 'ontime';
      case HabitLogStatus.late:
        return 'late';
      case HabitLogStatus.missed:
        return 'missed';
    }
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is DateTime) {
      return DateTime.utc(raw.year, raw.month, raw.day);
    }
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.parse(raw);
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    }
    throw ArgumentError.value(raw, 'date', 'must be an ISO date or DateTime');
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is String && raw.isNotEmpty) {
      return DateTime.parse(raw).toUtc();
    }
    throw ArgumentError.value(raw, 'timestamp', 'must be an ISO timestamp');
  }

  static String _formatIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
