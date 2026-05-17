import 'package:murabbi_mobile/data/datasources/habit_data_source.dart';
import 'package:murabbi_mobile/data/mappers/habit_log_mapper.dart';
import 'package:murabbi_mobile/data/mappers/habit_mapper.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_subtask_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Implémentation Supabase du [HabitRepository] — délègue à un
/// [HabitDataSource] et passe par les mappers (`HabitMapper`,
/// `HabitLogMapper`) pour la sérialisation.
///
/// Le datasource est un wrapper thin Supabase ; la traduction d'erreur
/// (PostgrestException → failure typée) reste possible ici, mais V1 laisse
/// remonter telles quelles (pas encore de `HabitFailure` domain — cf. issue
/// de suivi). Le pattern suit `PrayerRepositoryImpl`.
///
/// Note : les sous-tâches (`HabitSubtask`) ne sont pas encore branchées sur
/// Supabase dans cette slice (#149) — méthodes `*Subtask*` non implémentées,
/// couvertes par une issue ultérieure.
class HabitRepositoryImpl implements HabitRepository {
  final HabitDataSource _ds;

  const HabitRepositoryImpl(this._ds);

  @override
  Future<List<Habit>> getHabits(UserId userId) async {
    final rows = await _ds.getHabits(userId.value);
    return rows.map(HabitMapper.fromRow).toList(growable: false);
  }

  @override
  Future<Habit> createHabit({
    required UserId userId,
    required Habit habit,
  }) async {
    final row = HabitMapper.toRow(habit)..['user_id'] = userId.value;
    final created = await _ds.createHabit(row);
    return HabitMapper.fromRow(created);
  }

  @override
  Future<Habit> updateHabit(Habit habit) async {
    final updated = await _ds.updateHabit(HabitMapper.toRow(habit));
    return HabitMapper.fromRow(updated);
  }

  @override
  Future<void> deleteHabit(HabitId habitId) {
    return _ds.deleteHabit(habitId.value);
  }

  @override
  Future<void> toggleHabitLog({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus status,
  }) {
    final log = HabitLog(habitId: habitId, date: date, status: status);
    return _ds.upsertHabitLog(HabitLogMapper.toRow(log));
  }

  @override
  Future<void> logHabit(HabitLog log) {
    return _ds.upsertHabitLog(HabitLogMapper.toRow(log));
  }

  /// Renvoie l'historique de logs d'une habitude sur la plage [from]..[to]
  /// (inclus). Nécessaire pour les stats / heatmap (`GetHabitStatsUseCase`).
  Future<List<HabitLog>> getLogsForHabit({
    required HabitId habitId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _ds.getLogsForHabit(
      habitId: habitId.value,
      from: _formatIsoDate(from),
      to: _formatIsoDate(to),
    );
    return rows.map(HabitLogMapper.fromRow).toList(growable: false);
  }

  static String _formatIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  // -------------------- Subtasks — non branchés en slice #149 ---------------

  @override
  Future<List<HabitSubtask>> getSubtasks(HabitId habitId) {
    throw UnimplementedError(
      'HabitSubtask Supabase persistence non implémentée (issue de suivi)',
    );
  }

  @override
  Future<HabitSubtask> addSubtask(HabitSubtask subtask) {
    throw UnimplementedError(
      'HabitSubtask Supabase persistence non implémentée (issue de suivi)',
    );
  }

  @override
  Future<HabitSubtask> updateSubtask(HabitSubtask subtask) {
    throw UnimplementedError(
      'HabitSubtask Supabase persistence non implémentée (issue de suivi)',
    );
  }

  @override
  Future<void> deleteSubtask(HabitSubtaskId subtaskId) {
    throw UnimplementedError(
      'HabitSubtask Supabase persistence non implémentée (issue de suivi)',
    );
  }

  @override
  Future<void> reorderSubtasks({
    required HabitId habitId,
    required List<HabitSubtaskId> orderedIds,
  }) {
    throw UnimplementedError(
      'HabitSubtask Supabase persistence non implémentée (issue de suivi)',
    );
  }
}
