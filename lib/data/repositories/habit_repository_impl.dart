import 'package:murabbi_mobile/core/network/current_user_id_resolver.dart';
import 'package:murabbi_mobile/core/utils/ownership_guard.dart';
import 'package:murabbi_mobile/data/datasources/habit_data_source.dart';
import 'package:murabbi_mobile/data/mappers/habit_log_mapper.dart';
import 'package:murabbi_mobile/data/mappers/habit_mapper.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/habit_subtask.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';
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
class HabitRepositoryImpl with OwnershipGuard implements HabitRepository {
  final HabitDataSource _ds;

  /// Resolver d'`userId` courant (issue #202 / M3) — utilisé par
  /// [OwnershipGuard] pour vérifier qu'un repository n'est jamais appelé
  /// avec un `userId` étranger à la session.
  final CurrentUserIdResolver _currentUserIdResolver;

  const HabitRepositoryImpl(
    this._ds, {
    required CurrentUserIdResolver currentUserIdResolver,
  }) : _currentUserIdResolver = currentUserIdResolver;

  Future<void> _guardOwnership(UserId userId) async {
    final currentId = await _currentUserIdResolver.currentUserId();
    assertOwnership(
      requestedId: userId.value,
      currentId: currentId,
      failureIfMismatch: const HabitFailure.unauthorized(),
    );
  }

  @override
  Future<List<Habit>> getHabits(UserId userId) async {
    await _guardOwnership(userId);
    final rows = await _ds.getHabits(userId.value);
    return rows.map(HabitMapper.fromRow).toList(growable: false);
  }

  @override
  Future<Habit> createHabit({
    required UserId userId,
    required Habit habit,
  }) async {
    await _guardOwnership(userId);
    final row = HabitMapper.toRow(habit)..['user_id'] = userId.value;
    final created = await _ds.createHabit(row);
    return HabitMapper.fromRow(created);
  }

  @override
  Future<Habit> updateHabit(Habit habit) async {
    await _guardOwnership(habit.userId);
    final updated = await _ds.updateHabit(HabitMapper.toRow(habit));
    return HabitMapper.fromRow(updated);
  }

  @override
  Future<void> deleteHabit(HabitId habitId, UserId userId) async {
    await _guardOwnership(userId);
    return _ds.deleteHabit(habitId.value);
  }

  /// #164 — Délègue à la RPC `toggle_habit_log` via [HabitDataSource].
  ///
  /// Les [HabitFailure] levées par le datasource (date future,
  /// rétrodatation > 8 jours, erreur DB) remontent telles quelles vers la
  /// couche presentation — aucune traduction supplémentaire ici.
  @override
  Future<void> toggleHabitLog({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus status,
  }) async {
    await _ds.toggleHabitLog(
      habitId: habitId.value,
      date: date,
      status: HabitLogMapper.statusToSql(status),
    );
  }

  @override
  Future<void> logHabit(HabitLog log) {
    return _ds.upsertHabitLog(HabitLogMapper.toRow(log));
  }

  /// Renvoie l'historique de logs d'une habitude sur la plage [from]..[to]
  /// (inclus). Nécessaire pour les stats / heatmap (`GetHabitStatsUseCase`).
  @override
  Future<List<HabitLog>> getLogsForHabit({
    required HabitId habitId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _ds.getLogsForHabit(
      habitId: habitId.value,
      from: HabitLogMapper.formatIsoDate(from),
      to: HabitLogMapper.formatIsoDate(to),
    );
    return rows.map(HabitLogMapper.fromRow).toList(growable: false);
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
