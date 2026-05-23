// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/services/background/workmanager_dispatcher.dart';

/// Mocks des interfaces définies dans workmanager_dispatcher.dart.
class _MockWorkManagerRunner extends Mock implements WorkManagerRunner {}

class _MockScheduleOccurrences extends Mock
    implements ScheduleOccurrencesUseCase {}

class _MockExpireOverdue extends Mock
    implements ExpireOverdueOccurrencesUseCase {}

class _MockNotificationRescheduler extends Mock
    implements NotificationRescheduler {}

void main() {
  late _MockWorkManagerRunner runner;
  late _MockScheduleOccurrences scheduleUseCase;
  late _MockExpireOverdue expireUseCase;
  late _MockNotificationRescheduler rescheduler;
  late WorkManagerDispatcher sut;

  setUp(() {
    runner = _MockWorkManagerRunner();
    scheduleUseCase = _MockScheduleOccurrences();
    expireUseCase = _MockExpireOverdue();
    rescheduler = _MockNotificationRescheduler();

    when(
      () =>
          runner.initialize(any(), isInDebugMode: any(named: 'isInDebugMode')),
    ).thenAnswer((_) async {});
    when(
      () => runner.registerPeriodicTask(
        any(),
        any(),
        frequency: any(named: 'frequency'),
        flexInterval: any(named: 'flexInterval'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => runner.registerOneOffTask(any(), any()),
    ).thenAnswer((_) async {});
    when(() => scheduleUseCase.call()).thenAnswer((_) async {});
    when(() => expireUseCase.call()).thenAnswer((_) async {});
    when(() => rescheduler.rescheduleAll()).thenAnswer((_) async {});

    sut = WorkManagerDispatcher(
      runner: runner,
      scheduleOccurrencesUseCase: scheduleUseCase,
      expireOverdueUseCase: expireUseCase,
      notificationRescheduler: rescheduler,
    );
  });

  // ------------------------------------------------------------------
  // Test 1 — initialize enregistre le callback dispatcher
  // ------------------------------------------------------------------
  test('initialize_registers_callback_dispatcher', () async {
    await sut.initialize();

    verify(
      () =>
          runner.initialize(any(), isInDebugMode: any(named: 'isInDebugMode')),
    ).called(1);
  });

  // ------------------------------------------------------------------
  // Test 2 — daily refresh planifié à 24h
  // ------------------------------------------------------------------
  test('daily_refresh_schedules_24h_period', () async {
    await sut.registerDailyRefresh();

    verify(
      () => runner.registerPeriodicTask(
        WorkManagerDispatcher.kTaskDailyOccurrenceRefresh,
        WorkManagerDispatcher.kTaskDailyOccurrenceRefresh,
        frequency: const Duration(hours: 24),
        flexInterval: any(named: 'flexInterval'),
      ),
    ).called(1);
  });

  // ------------------------------------------------------------------
  // Test 3 — grace expiry planifié à 15 min
  // ------------------------------------------------------------------
  test('grace_expiry_schedules_15min_period', () async {
    await sut.registerGraceExpirySweep();

    verify(
      () => runner.registerPeriodicTask(
        WorkManagerDispatcher.kTaskGraceExpirySweep,
        WorkManagerDispatcher.kTaskGraceExpirySweep,
        frequency: const Duration(minutes: 15),
        flexInterval: any(named: 'flexInterval'),
      ),
    ).called(1);
  });

  // ------------------------------------------------------------------
  // Test 4 — kTaskDailyOccurrenceRefresh → ScheduleOccurrencesUseCase
  // ------------------------------------------------------------------
  test('task_daily_refresh_calls_schedule_occurrences', () async {
    await sut.handleTask(WorkManagerDispatcher.kTaskDailyOccurrenceRefresh);

    verify(() => scheduleUseCase.call()).called(1);
  });

  // ------------------------------------------------------------------
  // Test 5 — kTaskGraceExpirySweep → ExpireOverdueOccurrencesUseCase
  // ------------------------------------------------------------------
  test('task_grace_sweep_calls_expire_overdue', () async {
    await sut.handleTask(WorkManagerDispatcher.kTaskGraceExpirySweep);

    verify(() => expireUseCase.call()).called(1);
  });

  // ------------------------------------------------------------------
  // Test 6 — kTaskBootReschedule → NotificationRescheduler.rescheduleAll
  // ------------------------------------------------------------------
  test('task_boot_reschedule_reregisters_all_occurrences', () async {
    await sut.handleTask(WorkManagerDispatcher.kTaskBootReschedule);

    verify(() => rescheduler.rescheduleAll()).called(1);
  });

  // ------------------------------------------------------------------
  // Test 7 — task inconnue → log warning, retourne false
  // ------------------------------------------------------------------
  test('dispatcher_handles_unknown_task_gracefully', () async {
    final result = await sut.handleTask('totally_unknown_task');

    expect(result, isFalse);
    // Aucun use case appelé.
    verifyNever(() => scheduleUseCase.call());
    verifyNever(() => expireUseCase.call());
    verifyNever(() => rescheduler.rescheduleAll());
  });

  // ------------------------------------------------------------------
  // Test 8 — exception dans handleTask → log error, retourne false
  // ------------------------------------------------------------------
  test('dispatcher_logs_error_on_failure', () async {
    when(() => scheduleUseCase.call()).thenThrow(Exception('Supabase down'));

    final result = await sut.handleTask(
      WorkManagerDispatcher.kTaskDailyOccurrenceRefresh,
    );

    expect(result, isFalse);
  });
}
