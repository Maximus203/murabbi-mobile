import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_clock_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_ticker_provider.dart';

void main() {
  test('dashboardTickerProvider émet la valeur initiale du clock', () async {
    final fixedNow = DateTime.utc(2026, 5, 14, 12, 0);
    final container = ProviderContainer(
      overrides: [dashboardClockProvider.overrideWithValue(() => fixedNow)],
    );
    addTearDown(container.dispose);

    final first = await container.read(dashboardTickerProvider.future);
    expect(first, fixedNow);
  });

  test('dashboardTickerProvider re-émet toutes les 30s via Timer.periodic '
      '(fakeAsync — closes #47)', () {
    fakeAsync((async) {
      // Clock mutable simulant le passage du temps virtuel.
      var current = DateTime.utc(2026, 5, 14, 12, 0);
      final container = ProviderContainer(
        overrides: [dashboardClockProvider.overrideWithValue(() => current)],
      );
      addTearDown(container.dispose);

      final emissions = <DateTime>[];
      final sub = container.listen(dashboardTickerProvider, (_, next) {
        if (next.hasValue) emissions.add(next.requireValue);
      }, fireImmediately: true);
      addTearDown(sub.close);

      // 1re émission synchrone (controller.add depuis onListen).
      async.flushMicrotasks();
      expect(
        emissions.length,
        greaterThanOrEqualTo(1),
        reason: 'Émission initiale immédiate manquante',
      );
      expect(emissions.first, DateTime.utc(2026, 5, 14, 12, 0));

      // Avance virtuellement de 30s + flushMicrotasks pour propager.
      current = DateTime.utc(2026, 5, 14, 12, 0, 30);
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();

      expect(
        emissions.length,
        greaterThanOrEqualTo(2),
        reason:
            'Le Timer.periodic devait avoir émis une 2e valeur après 30s '
            'virtuelles',
      );
      expect(
        emissions[1],
        DateTime.utc(2026, 5, 14, 12, 0, 30),
        reason: 'La 2e émission doit refléter le clock courant',
      );

      // Avance encore 60s : on attend +2 émissions de plus (30s + 30s).
      current = DateTime.utc(2026, 5, 14, 12, 1, 30);
      async.elapse(const Duration(seconds: 60));
      async.flushMicrotasks();

      expect(
        emissions.length,
        greaterThanOrEqualTo(4),
        reason: 'Après 90s totales virtuelles : 4 émissions attendues',
      );
    });
  });
}
