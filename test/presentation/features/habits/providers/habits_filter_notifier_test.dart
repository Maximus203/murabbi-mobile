import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_filter.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_filter_notifier.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('HabitsFilterNotifier', () {
    test('état initial = filtre neutre (all, name, query vide)', () {
      final container = makeContainer();
      final filter = container.read(habitsFilterProvider);

      expect(filter.query, isEmpty);
      expect(filter.status, HabitFilterStatus.all);
      expect(filter.sortBy, HabitSortBy.name);
    });

    test('setQuery met à jour la query sans toucher les autres champs', () {
      final container = makeContainer();
      final notifier = container.read(habitsFilterProvider.notifier);

      notifier.setSortBy(HabitSortBy.points);
      notifier.setQuery('coran');

      final filter = container.read(habitsFilterProvider);
      expect(filter.query, 'coran');
      expect(filter.sortBy, HabitSortBy.points);
    });

    test('setStatus met à jour le statut', () {
      final container = makeContainer();
      final notifier = container.read(habitsFilterProvider.notifier);

      notifier.setStatus(HabitFilterStatus.inactive);

      expect(
        container.read(habitsFilterProvider).status,
        HabitFilterStatus.inactive,
      );
    });

    test('setSortBy met à jour le critère de tri', () {
      final container = makeContainer();
      final notifier = container.read(habitsFilterProvider.notifier);

      notifier.setSortBy(HabitSortBy.category);

      expect(container.read(habitsFilterProvider).sortBy, HabitSortBy.category);
    });
  });
}
