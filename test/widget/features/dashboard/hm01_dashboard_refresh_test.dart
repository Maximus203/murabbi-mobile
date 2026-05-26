import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/daily_summary_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_state.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/niyyah_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/streak_delta_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/user_score_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/screens/hm_01_dashboard_screen.dart';
import 'package:murabbi_mobile/presentation/features/gamification/providers/level_up_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/today_habit_statuses_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_state.dart';

// ─── Notifiers de substitution ────────────────────────────────────────────────
//
// Chaque fake override `build()` pour retourner un état minimal
// sans appels réseau ni dépendances externes (repositories Supabase).

class _FakeDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardState> build() async => DashboardState(
    nowUtc: DateTime.utc(2026, 5, 26),
    nextPrayer: null,
    settingsNotConfigured: true, // évite _RemainingLabel + dashboardTicker
  );
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => null;
}

class _FakeLevelUpNotifier extends LevelUpNotifier {
  @override
  Level? build() => null;
}

class _FakeHabitsNotifier extends HabitsNotifier {
  @override
  Future<List<Habit>> build() async => const <Habit>[];
}

class _FakeTodaySalatNotifier extends TodaySalatNotifier {
  // Ne résout jamais : _StatsCard affiche '—' via whenOrNull, sans erreur.
  @override
  Future<TodaySalatState> build() => Completer<TodaySalatState>().future;
}

class _FakeCategoriesNotifier extends CategoriesNotifier {
  @override
  Future<List<Category>> build() async => const <Category>[];
}

class _FakeTodayHabitStatusesNotifier extends TodayHabitStatusesNotifier {
  @override
  Map<HabitId, HabitLogStatus> build() => const <HabitId, HabitLogStatus>{};
}

// ─── Tests ────────────────────────────────────────────────────────────────────

/// Widget test du comportement pull-to-refresh du dashboard HM-01
/// vis-à-vis de [streakDeltaProvider] (issue #6, Phase 5).
///
/// Vérifie que le geste "tirer pour rafraîchir" invalide [streakDeltaProvider]
/// afin que le delta de streak hebdomadaire soit recalculé à chaque refresh
/// (pas seulement au premier chargement).
void main() {
  testWidgets('pull-to-refresh invalide streakDeltaProvider (issue #6)', (
    tester,
  ) async {
    var streakBuildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardNotifierProvider.overrideWith(_FakeDashboardNotifier.new),
          authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
          levelUpNotifierProvider.overrideWith(_FakeLevelUpNotifier.new),
          habitsNotifierProvider.overrideWith(_FakeHabitsNotifier.new),
          todaySalatNotifierProvider.overrideWith(_FakeTodaySalatNotifier.new),
          categoriesNotifierProvider.overrideWith(_FakeCategoriesNotifier.new),
          todayHabitStatusesProvider.overrideWith(
            _FakeTodayHabitStatusesNotifier.new,
          ),
          userScoreProvider.overrideWith((_) async => null),
          dailySummaryProvider.overrideWith((_) async => null),
          niyyahProvider.overrideWith((_) async => null),
          streakDeltaProvider.overrideWith((_) async {
            streakBuildCount++;
            return 0;
          }),
        ],
        child: const MaterialApp(
          home: Hm01DashboardScreen(
            onConfigurePrayers: _noOp,
            onOpenSalat: _noOp,
          ),
        ),
      ),
    );

    // Stabilise le rendu initial : dashboardNotifier résout, widgets buildés,
    // streakDeltaProvider buildé une première fois par _StatsCard.
    await tester.pumpAndSettle();
    expect(
      streakBuildCount,
      1,
      reason:
          'streakDeltaProvider doit être buildé exactement une fois au chargement',
    );

    // Déclenche le pull-to-refresh via un fling vers le bas sur le ListView.
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    // Après le refresh, streakDeltaProvider doit avoir été invalidé et
    // reconstruit (buildCount ≥ 2).
    // Sans `ref.invalidate(streakDeltaProvider)` dans onRefresh → reste à 1
    // (RED). Avec le fix → passe à 2 (GREEN).
    expect(
      streakBuildCount,
      greaterThanOrEqualTo(2),
      reason: 'streakDeltaProvider doit être invalidé par le pull-to-refresh',
    );
  });
}

void _noOp() {}
