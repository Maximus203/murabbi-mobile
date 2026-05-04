import 'package:equatable/equatable.dart';

/// État pur d'un timer d'habitude in-app (spec v1.5 § 3.5 / § 5.5).
///
/// Snapshot immuable : chaque transition (`pause`, `resume`, `stop`) renvoie
/// une nouvelle instance. La couche présentation rafraîchit l'affichage en
/// appelant [remaining] avec l'horloge courante.
///
/// Hors scope domaine : la planification des notifications natives (5 min
/// restantes / fin) — déléguée à `services/notification_service.dart`
/// piloté par cet état.
class HabitTimer extends Equatable {
  /// Durée totale visée (target_value converti en `Duration`).
  final Duration totalDuration;

  /// Instant de démarrage initial (ne change jamais après [start]).
  final DateTime startedAt;

  /// Durée totale passée en pause depuis le démarrage.
  final Duration accumulatedPaused;

  /// Si le timer est actuellement en pause, instant où la pause a débuté.
  final DateTime? pausedAt;

  const HabitTimer._({
    required this.totalDuration,
    required this.startedAt,
    required this.accumulatedPaused,
    required this.pausedAt,
  });

  factory HabitTimer.start({required Duration target, required DateTime now}) {
    if (target <= Duration.zero) {
      throw ArgumentError.value(target, 'target', 'must be > 0');
    }
    return HabitTimer._(
      totalDuration: target,
      startedAt: now,
      accumulatedPaused: Duration.zero,
      pausedAt: null,
    );
  }

  bool get isPaused => pausedAt != null;
  bool get isRunning => !isPaused;

  /// Temps effectif déjà écoulé (hors pauses) à l'instant [at].
  ///
  /// **Pure** : aucun appel à `DateTime.now()`. Le caller passe l'instant
  /// de référence — c'est cette méthode que les use cases et tests doivent
  /// utiliser. Si le timer est en pause, [at] est ignoré et le temps est
  /// figé à l'instant de la pause.
  Duration elapsedAt({required DateTime at}) {
    final paused = pausedAt;
    final pauseUntil = paused ?? at;
    final raw = pauseUntil.difference(startedAt) - accumulatedPaused;
    return raw.isNegative ? Duration.zero : raw;
  }

  /// Helper non-pur destiné à la couche présentation (rafraîchissement UI
  /// périodique sans avoir à instancier un horloge mockable).
  ///
  /// **NE PAS UTILISER en domaine ni en tests** — préférer [elapsedAt].
  Duration elapsedNow() => elapsedAt(at: DateTime.now());

  /// Temps restant à l'instant [at], clampé à `[0, totalDuration]`.
  Duration remaining({required DateTime at}) {
    final el = elapsedAt(at: at);
    final remain = totalDuration - el;
    if (remain.isNegative) return Duration.zero;
    return remain;
  }

  /// Met en pause. Idempotent si déjà en pause.
  /// Fail-fast si [now] est antérieur à [startedAt] (temps non-monotone).
  HabitTimer pause({required DateTime now}) {
    if (isPaused) return this;
    if (now.isBefore(startedAt)) {
      throw ArgumentError.value(
        now,
        'now',
        'HabitTimer.pause requires monotonic time (now must be >= startedAt)',
      );
    }
    return HabitTimer._(
      totalDuration: totalDuration,
      startedAt: startedAt,
      accumulatedPaused: accumulatedPaused,
      pausedAt: now,
    );
  }

  /// Reprend après une pause. No-op si déjà en cours.
  /// Fail-fast si [now] est antérieur à `pausedAt` (temps non-monotone).
  HabitTimer resume({required DateTime now}) {
    final paused = pausedAt;
    if (paused == null) return this;
    if (now.isBefore(paused)) {
      throw ArgumentError.value(
        now,
        'now',
        'HabitTimer.resume requires monotonic time (now must be >= pausedAt)',
      );
    }
    final pauseDuration = now.difference(paused);
    return HabitTimer._(
      totalDuration: totalDuration,
      startedAt: startedAt,
      accumulatedPaused: accumulatedPaused + pauseDuration,
      pausedAt: null,
    );
  }

  /// Arrête le timer et retourne la durée effective écoulée à [now].
  /// Utilisée pour alimenter `HabitLog.duration`. Fail-fast si [now] est
  /// antérieur à [startedAt].
  Duration stop({required DateTime now}) {
    if (now.isBefore(startedAt)) {
      throw ArgumentError.value(
        now,
        'now',
        'HabitTimer.stop requires monotonic time (now must be >= startedAt)',
      );
    }
    return elapsedAt(at: now);
  }

  @override
  List<Object?> get props => [
    totalDuration,
    startedAt,
    accumulatedPaused,
    pausedAt,
  ];
}
