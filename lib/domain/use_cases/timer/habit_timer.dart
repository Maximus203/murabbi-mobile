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

  /// Temps effectif déjà écoulé (hors pauses).
  Duration get elapsed {
    final ref = pausedAt ?? DateTime.now();
    return _elapsedAt(ref);
  }

  Duration _elapsedAt(DateTime now) {
    final paused = pausedAt;
    final pauseUntil = paused ?? now;
    final raw = pauseUntil.difference(startedAt) - accumulatedPaused;
    return raw.isNegative ? Duration.zero : raw;
  }

  /// Temps restant à l'instant [at], clampé à `[0, totalDuration]`.
  Duration remaining({required DateTime at}) {
    final el = _elapsedAt(at);
    final remain = totalDuration - el;
    if (remain.isNegative) return Duration.zero;
    return remain;
  }

  /// Met en pause. Idempotent si déjà en pause.
  HabitTimer pause({required DateTime now}) {
    if (isPaused) return this;
    return HabitTimer._(
      totalDuration: totalDuration,
      startedAt: startedAt,
      accumulatedPaused: accumulatedPaused,
      pausedAt: now,
    );
  }

  /// Reprend après une pause. No-op si déjà en cours.
  HabitTimer resume({required DateTime now}) {
    final paused = pausedAt;
    if (paused == null) return this;
    final pauseDuration = now.difference(paused);
    return HabitTimer._(
      totalDuration: totalDuration,
      startedAt: startedAt,
      accumulatedPaused: accumulatedPaused + pauseDuration,
      pausedAt: null,
    );
  }

  /// Arrête le timer et retourne la durée effective écoulée à [now].
  /// Utilisée pour alimenter `HabitLog.duration`.
  Duration stop({required DateTime now}) {
    return _elapsedAt(now);
  }

  @override
  List<Object?> get props => [
    totalDuration,
    startedAt,
    accumulatedPaused,
    pausedAt,
  ];
}
