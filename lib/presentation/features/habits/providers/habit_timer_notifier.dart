import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Statut du timer in-app (spec v1.5 § 3.5, ADR-008).
enum HabitTimerStatus { initial, running, paused, completed }

/// État immutable du timer.
class HabitTimerState {
  final HabitTimerStatus status;
  final Duration target;
  final Duration elapsed;

  const HabitTimerState({
    required this.status,
    required this.target,
    this.elapsed = Duration.zero,
  });

  /// Temps restant (jamais négatif).
  Duration get remaining {
    final r = target - elapsed;
    return r.isNegative ? Duration.zero : r;
  }

  /// Progression entre 0.0 et 1.0.
  double get progress {
    if (target.inSeconds == 0) return 1.0;
    return (elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0);
  }

  bool get isCompleted => elapsed >= target;

  HabitTimerState copyWith({HabitTimerStatus? status, Duration? elapsed}) =>
      HabitTimerState(
        status: status ?? this.status,
        target: target,
        elapsed: elapsed ?? this.elapsed,
      );
}

/// Notifier du timer in-app (spec v1.5 § 3.5).
///
/// Famille indexée par la durée cible — une instance par habitude ouverte.
/// Cycle : initial → running ↔ paused → completed.
///
/// La méthode [forceElapsedForTest] est exposée uniquement pour les tests
/// unitaires afin de forcer l'état `completed` sans attendre le timer réel.
class HabitTimerNotifier extends FamilyNotifier<HabitTimerState, Duration> {
  Timer? _ticker;

  @override
  HabitTimerState build(Duration arg) {
    ref.onDispose(_cancelTicker);
    return HabitTimerState(target: arg, status: HabitTimerStatus.initial);
  }

  void play() {
    if (state.isCompleted) return;
    _cancelTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
    state = state.copyWith(status: HabitTimerStatus.running);
  }

  void pause() {
    _cancelTicker();
    state = state.copyWith(status: HabitTimerStatus.paused);
  }

  void stop() {
    _cancelTicker();
    state = HabitTimerState(
      target: state.target,
      status: HabitTimerStatus.initial,
    );
  }

  void _tick(Timer _) {
    final next = state.elapsed + const Duration(seconds: 1);
    if (next >= state.target) {
      _cancelTicker();
      state = state.copyWith(
        elapsed: state.target,
        status: HabitTimerStatus.completed,
      );
    } else {
      state = state.copyWith(elapsed: next, status: HabitTimerStatus.running);
    }
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Uniquement pour les tests unitaires — force elapsed à [value]
  /// et met le statut à [HabitTimerStatus.completed].
  // ignore: invalid_use_of_visible_for_testing_member
  void forceElapsedForTest(Duration value) {
    _cancelTicker();
    state = state.copyWith(elapsed: value, status: HabitTimerStatus.completed);
  }
}

final habitTimerProvider =
    NotifierProvider.family<HabitTimerNotifier, HabitTimerState, Duration>(
      HabitTimerNotifier.new,
    );
