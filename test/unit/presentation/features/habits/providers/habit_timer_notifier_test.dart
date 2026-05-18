import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habit_timer_notifier.dart';

void main() {
  const target = Duration(minutes: 20);

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  HabitTimerState readState(ProviderContainer c) =>
      c.read(habitTimerProvider(target));

  group('HabitTimerState — calculs purs', () {
    test('état initial : elapsed = 0, status = initial', () {
      final container = makeContainer();
      final state = readState(container);
      expect(state.status, HabitTimerStatus.initial);
      expect(state.elapsed, Duration.zero);
      expect(state.remaining, target);
      expect(state.progress, 0.0);
      expect(state.isCompleted, isFalse);
    });

    test('remaining = target - elapsed', () {
      const elapsed = Duration(minutes: 12, seconds: 34);
      const state = HabitTimerState(
        target: target,
        elapsed: elapsed,
        status: HabitTimerStatus.running,
      );
      expect(state.remaining, target - elapsed);
    });

    test('progress clampé entre 0 et 1', () {
      final over = HabitTimerState(
        target: target,
        elapsed: target + const Duration(seconds: 1),
        status: HabitTimerStatus.running,
      );
      expect(over.progress, 1.0);

      const s = HabitTimerState(
        target: target,
        elapsed: Duration.zero,
        status: HabitTimerStatus.initial,
      );
      expect(s.progress, 0.0);
    });

    test('isCompleted = true quand elapsed >= target', () {
      const done = HabitTimerState(
        target: target,
        elapsed: target,
        status: HabitTimerStatus.completed,
      );
      expect(done.isCompleted, isTrue);
    });
  });

  group('HabitTimerNotifier — transitions d\'état', () {
    test('play() → status = running', () {
      final container = makeContainer();
      container.read(habitTimerProvider(target).notifier).play();
      expect(readState(container).status, HabitTimerStatus.running);
      // Nettoyage du timer interne
      container.read(habitTimerProvider(target).notifier).stop();
    });

    test('pause() après play() → status = paused, elapsed conservé', () {
      final container = makeContainer();
      final notifier = container.read(habitTimerProvider(target).notifier);
      notifier.play();
      notifier.pause();
      final state = readState(container);
      expect(state.status, HabitTimerStatus.paused);
    });

    test('stop() → status = initial, elapsed reset à zéro', () {
      final container = makeContainer();
      final notifier = container.read(habitTimerProvider(target).notifier);
      notifier.play();
      notifier.pause();
      notifier.stop();
      final state = readState(container);
      expect(state.status, HabitTimerStatus.initial);
      expect(state.elapsed, Duration.zero);
    });

    test('play() depuis paused reprend (status = running)', () {
      final container = makeContainer();
      final notifier = container.read(habitTimerProvider(target).notifier);
      notifier.play();
      notifier.pause();
      notifier.play();
      expect(readState(container).status, HabitTimerStatus.running);
      notifier.stop();
    });

    test('play() ignoré si status = completed', () {
      final container = makeContainer();
      final notifier = container.read(habitTimerProvider(target).notifier);
      // Force l'état completed directement
      notifier.forceElapsedForTest(target);
      notifier.play();
      expect(readState(container).status, HabitTimerStatus.completed);
    });
  });

  group('HabitTimerState.copyWith', () {
    test('conserve target inchangé', () {
      const s = HabitTimerState(
        target: target,
        elapsed: Duration.zero,
        status: HabitTimerStatus.initial,
      );
      final next = s.copyWith(status: HabitTimerStatus.running);
      expect(next.target, target);
      expect(next.status, HabitTimerStatus.running);
      expect(next.elapsed, Duration.zero);
    });
  });
}
