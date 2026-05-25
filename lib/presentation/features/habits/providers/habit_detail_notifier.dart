import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/extensions/ref_score_invalidation.dart';
import 'package:murabbi_mobile/core/utils/action_serializer.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/delete_habit_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/get_habit_stats_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/log_habit_value_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_stats.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/services/connectivity/connectivity_service.dart';
import 'package:murabbi_mobile/services/sync/sync_service_provider.dart';

/// Use case providers HB-DETAIL (issue #153).
final deleteHabitUseCaseProvider = Provider<DeleteHabitUseCase>((ref) {
  return DeleteHabitUseCase(ref.watch(habitRepositoryProvider));
});

final getHabitStatsUseCaseProvider = Provider<GetHabitStatsUseCase>((ref) {
  return const GetHabitStatsUseCase();
});

final logHabitValueUseCaseProvider = Provider<LogHabitValueUseCase>((ref) {
  return LogHabitValueUseCase(ref.watch(habitRepositoryProvider));
});

/// État de l'écran détail habitude HB-DETAIL.
///
/// Agrège l'habitude, ses statistiques calculées par [GetHabitStatsUseCase],
/// et les 7 logs les plus récents pour la section historique.
class HabitDetailState extends Equatable {
  final Habit habit;
  final HabitStats stats;

  /// 7 logs les plus récents (date décroissante), section historique.
  final List<HabitLog> recentLogs;

  const HabitDetailState({
    required this.habit,
    required this.stats,
    required this.recentLogs,
  });

  @override
  List<Object?> get props => [habit, stats, recentLogs];
}

/// Notifier de l'écran détail habitude (issue #153).
///
/// Famille indexée par `habitId` — charge l'habitude, calcule les stats sur
/// les 30 derniers jours de logs, et expose la suppression.
class HabitDetailNotifier
    extends FamilyAsyncNotifier<HabitDetailState, String> {
  /// Nombre maximum de logs affichés dans la section historique.
  static const int historyLimit = 7;

  /// Fenêtre d'historique chargée pour le calcul des stats / heatmap.
  static const int _windowDays = 30;

  /// Sérialiseur d'appels concurrents (issue #198 / M4) — protège
  /// `deleteHabit` d'un double-tap rapide sur le bouton de suppression.
  final ActionSerializer _serializer = ActionSerializer();

  late String _habitId;

  @override
  Future<HabitDetailState> build(String habitId) async {
    _habitId = habitId;
    return _load(habitId);
  }

  Future<HabitDetailState> _load(String habitId) async {
    final repo = ref.read(habitRepositoryProvider);
    final habits = await ref
        .read(getHabitsUseCaseProvider)
        .call(_resolveUserId());
    final matches = habits.where((h) => h.id.value == habitId).toList();
    if (matches.isEmpty) {
      throw StateError('Habit not found: $habitId');
    }
    final habit = matches.first;

    final reference = _today();
    final from = reference.subtract(const Duration(days: _windowDays - 1));
    final logs = await repo.getLogsForHabit(
      habitId: HabitId(habitId),
      from: from,
      to: reference,
    );

    final stats = ref
        .read(getHabitStatsUseCaseProvider)
        .call(habitId: HabitId(habitId), logs: logs, referenceDate: reference);

    final recentLogs = [...logs]..sort((a, b) => b.date.compareTo(a.date));

    return HabitDetailState(
      habit: habit,
      stats: stats,
      recentLogs: recentLogs.take(historyLimit).toList(growable: false),
    );
  }

  /// Valide l'habitude courante — pattern Optimistic UI + sync queue (M2).
  ///
  /// **Séquence** :
  /// 1. Met à jour l'état local immédiatement (sans attente réseau).
  /// 2. Enqueue l'opération dans SQLite via [SyncService] (aucun appel réseau).
  /// 3. Si online : déclenche [SyncService.processPendingQueue] immédiatement.
  /// 4. Invalide le cache de score (M6).
  ///
  /// Protégé par [ActionSerializer] contre les double-taps (M4 / BUG-003).
  Future<void> logHabit(HabitLogStatus status, {int? actualValue}) async {
    await _serializer.run<void>(() async {
      // 1. Optimistic update — visible immédiatement dans l'UI.
      _applyOptimisticLog(status);

      // 2. Enqueue dans SQLite (aucun appel réseau garanti).
      await ref.read(syncServiceProvider).enqueueLogHabit(
        habitId: _habitId,
        userId: _resolveUserId().value,
        status: status,
        date: _today(),
        actualValue: actualValue,
      );

      // 3. Sync immédiate si online — replay de la queue entière.
      // On lit le service directement (pas le StreamProvider) pour obtenir
      // le statut courant de façon fiable sans attendre la première émission.
      final isOnline =
          await ref.read(connectivityServiceProvider).isOnline();
      if (isOnline) {
        await ref.read(syncServiceProvider).processPendingQueue();
      }

      // 4. Invalide le cache score (M6 — le log peut modifier le total).
      ref.invalidateScoreCache();
    });
  }

  /// Supprime l'habitude courante via [DeleteHabitUseCase] puis invalide la
  /// liste HA-01 pour qu'elle se rafraîchisse.
  Future<void> deleteHabit() async {
    await _serializer.run<void>(() async {
      await ref.read(deleteHabitUseCaseProvider).call(HabitId(_habitId));
      ref.invalidate(habitsNotifierProvider);
      // Issue #196 (M6) : la suppression peut impacter le total de points.
      ref.invalidateScoreCache();
    });
  }

  /// Met à jour l'état local sans réseau (optimistic).
  ///
  /// Ajoute [optimisticLog] en tête de [HabitDetailState.recentLogs] et
  /// limite la liste à [historyLimit] entrées.
  void _applyOptimisticLog(HabitLogStatus status) {
    final current = state.valueOrNull;
    if (current == null) return;

    final optimisticLog = HabitLog(
      habitId: HabitId(_habitId),
      date: _today(),
      status: status,
    );

    final updatedLogs =
        [optimisticLog, ...current.recentLogs]
            .take(historyLimit)
            .toList(growable: false);

    state = AsyncValue.data(
      HabitDetailState(
        habit: current.habit,
        stats: current.stats,
        recentLogs: updatedLogs,
      ),
    );
  }

  /// Recharge habitude + stats (après un log par exemple).
  Future<void> refreshStats() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(_habitId));
    // Issue #196 (M6) : refreshStats est appelé après un log → score périmé.
    ref.invalidateScoreCache();
  }

  /// Résout l'userId courant — les routes habits sont gardées par
  /// `auth_redirect`, la valeur synthétique couvre les contextes de test
  /// sans session (le repo Supabase filtre de toute façon par RLS).
  UserId _resolveUserId() {
    final user = ref.read(authNotifierProvider).valueOrNull;
    return user?.id ?? UserId('anonymous');
  }

  DateTime _today() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }
}

final habitDetailNotifierProvider =
    AsyncNotifierProvider.family<HabitDetailNotifier, HabitDetailState, String>(
      HabitDetailNotifier.new,
    );
