import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_schedule.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../helpers/test_uuids.dart';

/// Tests de régression #145 — une habitude quotidienne doit être due le jour
/// même de sa création, et donc apparaître dans « Habitudes du jour ».
void main() {
  Habit habit({
    required HabitFrequencyType frequencyType,
    Set<int>? activeDays,
    int? monthlyDay,
    int frequency = 1,
  }) {
    return Habit(
      id: HabitId(kHabitIdAlpha),
      userId: UserId(kUserIdAlpha),
      name: NonEmptyString('Lecture'),
      categoryId: CategoryId(kCategoryIdReligion),
      frequencyType: frequencyType,
      frequency: frequency,
      activeDays: activeDays ?? {1, 2, 3, 4, 5, 6, 7},
      points: HabitPoints(3),
      isSystem: false,
      monthlyDay: monthlyDay,
    );
  }

  // 2026-05-17 est un dimanche (weekday == 7).
  final sunday = DateTime(2026, 5, 17);

  group('Habit.isDueOn', () {
    test('une habitude daily est due tous les jours', () {
      final h = habit(frequencyType: HabitFrequencyType.daily);
      expect(h.isDueOn(sunday), isTrue);
      expect(h.isDueOn(DateTime(2026, 5, 18)), isTrue);
    });

    test('une habitude perDay est due tous les jours', () {
      final h = habit(frequencyType: HabitFrequencyType.perDay, frequency: 3);
      expect(h.isDueOn(sunday), isTrue);
    });

    test('une habitude weekly est due si le weekday du jour est actif', () {
      final h = habit(
        frequencyType: HabitFrequencyType.weekly,
        activeDays: {7},
      );
      expect(h.isDueOn(sunday), isTrue);
      expect(h.isDueOn(DateTime(2026, 5, 18)), isFalse);
    });

    test('une habitude perWeek est due si le weekday du jour est actif', () {
      final h = habit(
        frequencyType: HabitFrequencyType.perWeek,
        activeDays: {1, 3},
        frequency: 2,
      );
      // 2026-05-18 est lundi (weekday 1).
      expect(h.isDueOn(DateTime(2026, 5, 18)), isTrue);
      expect(h.isDueOn(sunday), isFalse);
    });

    test('une habitude monthly est due le jour du mois correspondant', () {
      final h = habit(
        frequencyType: HabitFrequencyType.monthly,
        monthlyDay: 17,
      );
      expect(h.isDueOn(sunday), isTrue);
      expect(h.isDueOn(DateTime(2026, 5, 18)), isFalse);
    });

    test('une habitude custom est considérée comme due tous les jours', () {
      final h = habit(frequencyType: HabitFrequencyType.custom);
      expect(h.isDueOn(sunday), isTrue);
    });
  });

  group('habitsDueOn', () {
    test('ne retient que les habitudes dues le jour donné', () {
      final daily = habit(frequencyType: HabitFrequencyType.daily);
      final weeklyMonday = Habit(
        id: HabitId(kHabitIdBeta),
        userId: UserId(kUserIdAlpha),
        name: NonEmptyString('Sport'),
        categoryId: CategoryId(kCategoryIdSport),
        frequencyType: HabitFrequencyType.weekly,
        frequency: 1,
        activeDays: {1},
        points: HabitPoints(3),
        isSystem: false,
      );
      final due = habitsDueOn([daily, weeklyMonday], sunday);
      expect(due, [daily]);
    });
  });
}
