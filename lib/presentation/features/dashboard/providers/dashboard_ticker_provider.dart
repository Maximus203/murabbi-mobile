import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_clock_provider.dart';
import 'package:murabbi_mobile/presentation/theme/app_duration.dart';

/// Ticker périodique scoped au countdown "Dans X min" de _NextPrayerCard.
///
/// **Critique** : ce provider est **séparé** du [dashboardNotifierProvider]
/// — sinon chaque tick déclencherait un re-fetch des horaires via
/// `GetPrayerTimesUseCase` (rebuild storm 60×/h, audit TL §B.2 PR #42).
///
/// Émet [DateTime] UTC toutes les 30 s. Seul `_RemainingLabel` watch ce
/// provider, le reste du Dashboard (header, placeholders, signout) reste
/// silencieux entre les ticks.
final dashboardTickerProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final clock = ref.read(dashboardClockProvider);
  late StreamController<DateTime> controller;
  Timer? timer;
  controller = StreamController<DateTime>(
    onListen: () {
      controller.add(clock());
      timer = Timer.periodic(
        AppDuration.dashboardTick,
        (_) => controller.add(clock()),
      );
    },
    onCancel: () => timer?.cancel(),
  );
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});
