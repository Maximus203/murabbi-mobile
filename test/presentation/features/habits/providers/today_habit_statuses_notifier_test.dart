import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/in_memory_habit_repository.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/today_habit_statuses_notifier.dart';

/// Repo dont `toggleHabitLog` peut échouer — simule une panne réseau.
class _FailingRepo extends InMemoryHabitRepository {
  bool shouldThrow = false;

  @override
  Future<void> toggleHabitLog({
    required HabitId habitId,
    required DateTime date,
    required HabitLogStatus status,
  }) async {
    if (shouldThrow) throw StateError('boom — Supabase down');
  }
}

void main() {
  final habitId = HabitId('h1');

  ProviderContainer makeContainer(InMemoryHabitRepository repo) {
    final c = ProviderContainer(
      overrides: [habitRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('état initial vide', () {
    final c = makeContainer(InMemoryHabitRepository());
    expect(c.read(todayHabitStatusesProvider), isEmpty);
  });

  test('toggle null → onTime : update optimiste immédiat', () async {
    final c = makeContainer(InMemoryHabitRepository());
    final notifier = c.read(todayHabitStatusesProvider.notifier);

    final future = notifier.toggle(habitId);
    // L'état est mis à jour AVANT que le future async soit résolu.
    expect(c.read(todayHabitStatusesProvider)[habitId], HabitLogStatus.onTime);
    await future;
    expect(c.read(todayHabitStatusesProvider)[habitId], HabitLogStatus.onTime);
  });

  test('cycle complet onTime → late → missed → onTime', () async {
    final c = makeContainer(InMemoryHabitRepository());
    final notifier = c.read(todayHabitStatusesProvider.notifier);

    await notifier.toggle(habitId);
    expect(c.read(todayHabitStatusesProvider)[habitId], HabitLogStatus.onTime);
    await notifier.toggle(habitId);
    expect(c.read(todayHabitStatusesProvider)[habitId], HabitLogStatus.late);
    await notifier.toggle(habitId);
    expect(c.read(todayHabitStatusesProvider)[habitId], HabitLogStatus.missed);
    await notifier.toggle(habitId);
    expect(c.read(todayHabitStatusesProvider)[habitId], HabitLogStatus.onTime);
  });

  test(
    'rollback : état revient à la valeur précédente si le repo throw',
    () async {
      final repo = _FailingRepo();
      final c = makeContainer(repo);
      final notifier = c.read(todayHabitStatusesProvider.notifier);

      // Premier toggle réussi → onTime.
      await notifier.toggle(habitId);
      expect(
        c.read(todayHabitStatusesProvider)[habitId],
        HabitLogStatus.onTime,
      );

      // Second toggle échoue → rollback vers onTime.
      repo.shouldThrow = true;
      await expectLater(notifier.toggle(habitId), throwsA(isA<Object>()));
      expect(
        c.read(todayHabitStatusesProvider)[habitId],
        HabitLogStatus.onTime,
      );
    },
  );

  test('rollback depuis null : la clé est retirée si le repo throw', () async {
    final repo = _FailingRepo()..shouldThrow = true;
    final c = makeContainer(repo);
    final notifier = c.read(todayHabitStatusesProvider.notifier);

    await expectLater(notifier.toggle(habitId), throwsA(isA<Object>()));
    expect(c.read(todayHabitStatusesProvider).containsKey(habitId), isFalse);
  });
}
