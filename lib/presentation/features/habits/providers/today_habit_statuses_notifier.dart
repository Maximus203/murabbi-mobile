import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/extensions/ref_score_invalidation.dart';
import 'package:murabbi_mobile/core/utils/action_serializer.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/use_cases/habits/toggle_habit_log_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';

/// Statuts de log « aujourd'hui » par habitude (issue #151).
///
/// V1 : l'historique de logs n'est pas rechargé au boot — l'état démarre
/// vide et se remplit au fil des taps utilisateur. La persistence Supabase
/// est faite côté repository ; ce notifier ne gère que l'état UI optimiste.
class TodayHabitStatusesNotifier
    extends Notifier<Map<HabitId, HabitLogStatus>> {
  /// Sérialiseur d'appels concurrents (issue #198 / M4) — un double-tap
  /// rapide produit un seul appel `toggleHabitLog` côté repository.
  final ActionSerializer _serializer = ActionSerializer();

  @override
  Map<HabitId, HabitLogStatus> build() => const {};

  /// Date du log — défaut documenté Q-LOG-01.
  // TODO(Q-LOG-01) à valider PO : un reset après minuit logge sur la date
  // du jour courant, pas la veille.
  DateTime _logDate() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  /// Fait avancer le statut de [habitId] dans le cycle, avec update optimiste
  /// et rollback en cas d'échec de la persistence.
  Future<void> toggle(HabitId habitId) async {
    await _serializer.run<void>(() async {
      final previous = state[habitId];
      final next = ToggleHabitLogUseCase.nextStatus(previous);

      // 1. Update optimiste — la UI réagit immédiatement.
      state = {...state, habitId: next};

      try {
        // 2. Persistence.
        await ref
            .read(toggleHabitLogUseCaseProvider)
            .call(habitId: habitId, date: _logDate(), currentStatus: previous);
        // Issue #196 (M6) : invalide le score dashboard après mutation réussie.
        ref.invalidateScoreCache();
      } catch (e, st) {
        // 3. Rollback — restaure l'état précédent et propage l'erreur.
        appLog.e('toggleHabitLog failed', error: e, stackTrace: st);
        if (previous == null) {
          final rolled = {...state}..remove(habitId);
          state = rolled;
        } else {
          state = {...state, habitId: previous};
        }
        rethrow;
      }
    });
  }
}

final todayHabitStatusesProvider =
    NotifierProvider<TodayHabitStatusesNotifier, Map<HabitId, HabitLogStatus>>(
      TodayHabitStatusesNotifier.new,
    );
