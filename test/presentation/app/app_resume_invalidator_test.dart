import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/app_resume_invalidator.dart';

void main() {
  group('AppResumeInvalidator', () {
    test('appelle onResumeAfterLongPause si pause > seuil', () {
      var calls = 0;
      var now = DateTime(2026, 1, 1, 12);
      final invalidator = AppResumeInvalidator(
        threshold: const Duration(minutes: 5),
        clock: () => now,
        onResumeAfterLongPause: () => calls++,
      );

      // Pause
      invalidator.didChangeAppLifecycleState(AppLifecycleState.paused);

      // 6 min plus tard → resume long
      now = now.add(const Duration(minutes: 6));
      invalidator.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(calls, 1);
    });

    test("n'appelle pas si pause < seuil", () {
      var calls = 0;
      var now = DateTime(2026, 1, 1, 12);
      final invalidator = AppResumeInvalidator(
        threshold: const Duration(minutes: 5),
        clock: () => now,
        onResumeAfterLongPause: () => calls++,
      );

      invalidator.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 2));
      invalidator.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(calls, 0);
    });

    test("n'appelle pas si resume sans pause préalable", () {
      var calls = 0;
      final invalidator = AppResumeInvalidator(
        threshold: const Duration(minutes: 5),
        clock: DateTime.now,
        onResumeAfterLongPause: () => calls++,
      );

      invalidator.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(calls, 0);
    });

    test(
      'reset _pausedAt après chaque resume — 2e cycle court ne déclenche pas',
      () {
        var calls = 0;
        var now = DateTime(2026, 1, 1, 12);
        final invalidator = AppResumeInvalidator(
          threshold: const Duration(minutes: 5),
          clock: () => now,
          onResumeAfterLongPause: () => calls++,
        );

        // 1er cycle long → call
        invalidator.didChangeAppLifecycleState(AppLifecycleState.paused);
        now = now.add(const Duration(minutes: 10));
        invalidator.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(calls, 1);

        // 2e cycle : resume immédiat sans pause → 0 nouvel appel
        invalidator.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(calls, 1);

        // 3e cycle : pause courte → 0 nouvel appel
        invalidator.didChangeAppLifecycleState(AppLifecycleState.paused);
        now = now.add(const Duration(minutes: 1));
        invalidator.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(calls, 1);
      },
    );

    test('ignore les états inactive/detached/hidden', () {
      var calls = 0;
      final invalidator = AppResumeInvalidator(
        threshold: const Duration(minutes: 5),
        clock: DateTime.now,
        onResumeAfterLongPause: () => calls++,
      );

      invalidator
        ..didChangeAppLifecycleState(AppLifecycleState.inactive)
        ..didChangeAppLifecycleState(AppLifecycleState.detached)
        ..didChangeAppLifecycleState(AppLifecycleState.hidden);

      expect(calls, 0);
    });
  });
}
