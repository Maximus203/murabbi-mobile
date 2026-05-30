import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
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

const _kTestUserId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

// ─── Notifiers de substitution ────────────────────────────────────────────────

class _FakeDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardState> build() async => DashboardState(
    nowUtc: DateTime.utc(2026, 5, 27),
    nextPrayer: null,
    settingsNotConfigured: true,
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

// ─── Factory score ────────────────────────────────────────────────────────────

UserScore _score({required int weeklyRank, int? previousWeekRank}) => UserScore(
  userId: UserId(_kTestUserId),
  totalPoints: 5000,
  weeklyPoints: 200,
  currentLevel: Level.salik,
  weeklyRank: weeklyRank,
  previousWeekRank: previousWeekRank,
);

// ─── Helper widget ─────────────────────────────────────────────────────────────

Widget _buildDashboard({required UserScore? score}) {
  return ProviderScope(
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
      userScoreProvider.overrideWith((_) async => score),
      dailySummaryProvider.overrideWith((_) async => null),
      niyyahProvider.overrideWith((_) async => null),
      streakDeltaProvider.overrideWith((_) async => 0),
    ],
    child: const MaterialApp(
      home: Hm01DashboardScreen(onConfigurePrayers: _noOp, onOpenSalat: _noOp),
    ),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

/// Tests d'intégration du mouvement de rang dans le dashboard HM-01.
///
/// Vérifie la chaîne complète :
///   userScoreProvider (stub) → _StatsCard → DashboardStatsGrid → texte visible
///
/// Couverture (issue #199, Q-F, feat/dashboard-rank-movement) :
///   - progression (previousWeekRank > weeklyRank) → "↗ N places"
///   - régression  (previousWeekRank < weeklyRank) → "↘ N places"
///   - première semaine (previousWeekRank = null)   → pas de sous-label
///   - mouvement nul (previousWeekRank = weeklyRank) → pas de sous-label
///   - singulier vs pluriel accordé correctement
void main() {
  group('HM-01 — rank movement sub-label (Q-F #199)', () {
    testWidgets(
      'progression : previousWeekRank=6, weeklyRank=3 → "↗ 3 places"',
      (tester) async {
        await tester.pumpWidget(
          _buildDashboard(score: _score(weeklyRank: 3, previousWeekRank: 6)),
        );
        await tester.pumpAndSettle();

        // rankMovement = 6 - 3 = 3 → montée de 3 places
        expect(find.text('↗ 3 places'), findsOneWidget);
      },
    );

    testWidgets(
      'régression : previousWeekRank=3, weeklyRank=5 → "↘ 2 places"',
      (tester) async {
        await tester.pumpWidget(
          _buildDashboard(score: _score(weeklyRank: 5, previousWeekRank: 3)),
        );
        await tester.pumpAndSettle();

        // rankMovement = 3 - 5 = -2 → descente de 2 places
        expect(find.text('↘ 2 places'), findsOneWidget);
      },
    );

    testWidgets('singulier : rankMovement = 1 → "↗ 1 place" (pas "places")', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildDashboard(score: _score(weeklyRank: 4, previousWeekRank: 5)),
      );
      await tester.pumpAndSettle();

      // rankMovement = 5 - 4 = 1 → singulier
      expect(find.text('↗ 1 place'), findsOneWidget);
      expect(find.text('↗ 1 places'), findsNothing);
    });

    testWidgets(
      'première semaine : previousWeekRank=null → pas de sous-label',
      (tester) async {
        await tester.pumpWidget(
          _buildDashboard(score: _score(weeklyRank: 2, previousWeekRank: null)),
        );
        await tester.pumpAndSettle();

        // rankMovement = null → ni ↗ ni ↘
        expect(find.textContaining('↗'), findsNothing);
        expect(find.textContaining('↘'), findsNothing);
      },
    );

    testWidgets(
      'mouvement nul : previousWeekRank == weeklyRank → pas de sous-label',
      (tester) async {
        await tester.pumpWidget(
          _buildDashboard(score: _score(weeklyRank: 3, previousWeekRank: 3)),
        );
        await tester.pumpAndSettle();

        // rankMovement = 3 - 3 = 0 → _StatsCard ne génère pas de sous-label
        expect(find.textContaining('↗'), findsNothing);
        expect(find.textContaining('↘'), findsNothing);
      },
    );

    testWidgets('score null (non connecté) → pas de sous-label', (
      tester,
    ) async {
      await tester.pumpWidget(_buildDashboard(score: null));
      await tester.pumpAndSettle();

      expect(find.textContaining('↗'), findsNothing);
      expect(find.textContaining('↘'), findsNothing);
    });
  });
}

void _noOp() {}
