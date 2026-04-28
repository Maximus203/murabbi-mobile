import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/entities/notification.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

void main() {
  group('PrayerStatus enum', () {
    test('has five values', () {
      expect(PrayerStatus.values.length, 5);
    });

    test('contains onTime, late, missed, pending, makeup', () {
      expect(
        PrayerStatus.values,
        containsAll([
          PrayerStatus.onTime,
          PrayerStatus.late,
          PrayerStatus.missed,
          PrayerStatus.pending,
          PrayerStatus.makeup,
        ]),
      );
    });
  });

  group('HabitFrequencyType enum', () {
    test('has six values', () {
      expect(HabitFrequencyType.values.length, 6);
    });

    test('contains all frequency types', () {
      expect(
        HabitFrequencyType.values,
        containsAll([
          HabitFrequencyType.daily,
          HabitFrequencyType.perWeek,
          HabitFrequencyType.weekly,
          HabitFrequencyType.monthly,
          HabitFrequencyType.custom,
        ]),
      );
    });
  });

  group('Habit with frequencyType', () {
    final habitId = HabitId('habit-uuid-001');
    final catId = CategoryId('cat-uuid-001');

    test('creates with daily frequencyType', () {
      final habit = Habit(
        id: habitId,
        name: NonEmptyString('Dhikr'),
        categoryId: catId,
        frequencyType: HabitFrequencyType.daily,
        frequency: 1,
        timeRange: HabitTimeRange.morning,
        activeDays: {1, 2, 3, 4, 5, 6, 7},
        points: HabitPoints(3),
        isSystem: false,
      );
      expect(habit.frequencyType, HabitFrequencyType.daily);
    });

    test('creates with monthly frequencyType', () {
      final habit = Habit(
        id: habitId,
        name: NonEmptyString('Bilan mensuel'),
        categoryId: catId,
        frequencyType: HabitFrequencyType.monthly,
        frequency: 1,
        timeRange: HabitTimeRange.anytime,
        activeDays: {1},
        points: HabitPoints(5),
        isSystem: false,
      );
      expect(habit.frequencyType, HabitFrequencyType.monthly);
    });

    test('creates with custom frequencyType', () {
      final habit = Habit(
        id: habitId,
        name: NonEmptyString('Custom routine'),
        categoryId: catId,
        frequencyType: HabitFrequencyType.custom,
        frequency: 3,
        timeRange: HabitTimeRange.evening,
        activeDays: {1, 3, 5},
        points: HabitPoints(4),
        isSystem: false,
      );
      expect(habit.frequencyType, HabitFrequencyType.custom);
    });
  });

  group('Level enum', () {
    test('has six values', () {
      expect(Level.values.length, 6);
    });

    test('contains all levels in order', () {
      expect(Level.values, [
        Level.aspirant,
        Level.murid,
        Level.salik,
        Level.mujahid,
        Level.wali,
        Level.murabbi,
      ]);
    });

    test('threshold returns correct point threshold', () {
      expect(Level.aspirant.threshold, 0);
      expect(Level.murid.threshold, 1000);
      expect(Level.salik.threshold, 5000);
      expect(Level.mujahid.threshold, 15000);
      expect(Level.wali.threshold, 40000);
      expect(Level.murabbi.threshold, 100000);
    });

    test('fromPoints returns aspirant for 0 points', () {
      expect(Level.fromPoints(0), Level.aspirant);
    });

    test('fromPoints returns murid at threshold', () {
      expect(Level.fromPoints(1000), Level.murid);
    });

    test('fromPoints returns salik at threshold', () {
      expect(Level.fromPoints(5000), Level.salik);
    });

    test('fromPoints returns mujahid at threshold', () {
      expect(Level.fromPoints(15000), Level.mujahid);
    });

    test('fromPoints returns wali at threshold', () {
      expect(Level.fromPoints(40000), Level.wali);
    });

    test('fromPoints returns murabbi at max threshold', () {
      expect(Level.fromPoints(100000), Level.murabbi);
    });

    test('fromPoints returns correct level for intermediate points', () {
      expect(Level.fromPoints(3000), Level.murid);
      expect(Level.fromPoints(999), Level.aspirant);
    });

    test('dailyGoal returns correct target per level', () {
      expect(Level.aspirant.dailyGoal, 60);
      expect(Level.murid.dailyGoal, 80);
      expect(Level.salik.dailyGoal, 100);
      expect(Level.mujahid.dailyGoal, 120);
      expect(Level.wali.dailyGoal, 150);
      expect(Level.murabbi.dailyGoal, 200);
    });

    test('dailyGoal increases monotonically with level', () {
      final goals = Level.values.map((l) => l.dailyGoal).toList();
      for (var i = 0; i < goals.length - 1; i++) {
        expect(goals[i], lessThan(goals[i + 1]));
      }
    });
  });

  group('User entity', () {
    final userId = UserId('user-uuid-001');

    test('creates with valid fields', () {
      final now = DateTime.now();
      final user = User(
        id: userId,
        displayName: NonEmptyString('Cherif'),
        email: NonEmptyString('cherif@example.com'),
        createdAt: now,
        level: Level.aspirant,
      );

      expect(user.id, userId);
      expect(user.displayName.value, 'Cherif');
      expect(user.email.value, 'cherif@example.com');
      expect(user.level, Level.aspirant);
    });

    test('two users with same id are equal', () {
      final now = DateTime.now();
      final a = User(
        id: userId,
        displayName: NonEmptyString('Cherif'),
        email: NonEmptyString('cherif@example.com'),
        createdAt: now,
        level: Level.aspirant,
      );
      final b = User(
        id: userId,
        displayName: NonEmptyString('Cherif'),
        email: NonEmptyString('cherif@example.com'),
        createdAt: now,
        level: Level.aspirant,
      );
      expect(a, equals(b));
    });

    test('two users with different ids are not equal', () {
      final now = DateTime.now();
      final a = User(
        id: UserId('user-uuid-001'),
        displayName: NonEmptyString('Cherif'),
        email: NonEmptyString('cherif@example.com'),
        createdAt: now,
        level: Level.aspirant,
      );
      final b = User(
        id: UserId('user-uuid-002'),
        displayName: NonEmptyString('Cherif'),
        email: NonEmptyString('cherif@example.com'),
        createdAt: now,
        level: Level.aspirant,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('PrayerDay entity', () {
    final userId = UserId('user-uuid-001');
    final today = DateTime(2026, 4, 27);

    test('creates with valid fields, all prayers pending', () {
      final day = PrayerDay(
        userId: userId,
        date: today,
        fajr: PrayerStatus.pending,
        dhuhr: PrayerStatus.pending,
        asr: PrayerStatus.pending,
        maghrib: PrayerStatus.pending,
        isha: PrayerStatus.pending,
      );

      expect(day.userId, userId);
      expect(day.date, today);
      expect(day.fajr, PrayerStatus.pending);
      expect(day.dhuhr, PrayerStatus.pending);
    });

    test('creates with mixed statuses', () {
      final day = PrayerDay(
        userId: userId,
        date: today,
        fajr: PrayerStatus.onTime,
        dhuhr: PrayerStatus.late,
        asr: PrayerStatus.missed,
        maghrib: PrayerStatus.onTime,
        isha: PrayerStatus.pending,
      );

      expect(day.fajr, PrayerStatus.onTime);
      expect(day.dhuhr, PrayerStatus.late);
      expect(day.asr, PrayerStatus.missed);
    });

    test('two PrayerDays with same userId and date are equal', () {
      final a = PrayerDay(
        userId: userId,
        date: today,
        fajr: PrayerStatus.onTime,
        dhuhr: PrayerStatus.onTime,
        asr: PrayerStatus.onTime,
        maghrib: PrayerStatus.onTime,
        isha: PrayerStatus.onTime,
      );
      final b = PrayerDay(
        userId: userId,
        date: today,
        fajr: PrayerStatus.onTime,
        dhuhr: PrayerStatus.onTime,
        asr: PrayerStatus.onTime,
        maghrib: PrayerStatus.onTime,
        isha: PrayerStatus.onTime,
      );
      expect(a, equals(b));
    });
  });

  group('Category entity', () {
    final catId = CategoryId('cat-uuid-001');

    test('creates with valid fields', () {
      final cat = Category(
        id: catId,
        name: NonEmptyString('Sport'),
        color: '#4A5568',
        icon: 'activity',
        points: HabitPoints(3),
        isSystem: true,
      );

      expect(cat.id, catId);
      expect(cat.name.value, 'Sport');
      expect(cat.isSystem, isTrue);
    });

    test('two categories with same id are equal', () {
      final a = Category(
        id: catId,
        name: NonEmptyString('Sport'),
        color: '#4A5568',
        icon: 'activity',
        points: HabitPoints(3),
        isSystem: true,
      );
      final b = Category(
        id: catId,
        name: NonEmptyString('Sport'),
        color: '#4A5568',
        icon: 'activity',
        points: HabitPoints(3),
        isSystem: true,
      );
      expect(a, equals(b));
    });
  });

  group('Habit entity', () {
    final habitId = HabitId('habit-uuid-001');
    final catId = CategoryId('cat-uuid-001');

    test('creates with valid fields', () {
      final habit = Habit(
        id: habitId,
        name: NonEmptyString('Morning run'),
        categoryId: catId,
        frequency: 5,
        timeRange: HabitTimeRange.morning,
        activeDays: {1, 2, 3, 4, 5},
        points: HabitPoints(5),
        isSystem: false,
      );

      expect(habit.id, habitId);
      expect(habit.name.value, 'Morning run');
      expect(habit.frequency, 5);
      expect(habit.isSystem, isFalse);
    });

    test('frequency must be positive', () {
      expect(
        () => Habit(
          id: habitId,
          name: NonEmptyString('Morning run'),
          categoryId: catId,
          frequency: 0,
          timeRange: HabitTimeRange.morning,
          activeDays: {1},
          points: HabitPoints(1),
          isSystem: false,
        ),
        throwsArgumentError,
      );
    });

    test('activeDays cannot be empty', () {
      expect(
        () => Habit(
          id: habitId,
          name: NonEmptyString('Morning run'),
          categoryId: catId,
          frequency: 1,
          timeRange: HabitTimeRange.morning,
          activeDays: {},
          points: HabitPoints(1),
          isSystem: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('HabitLog entity', () {
    final habitId = HabitId('habit-uuid-001');
    final date = DateTime(2026, 4, 27);

    test('creates with valid fields', () {
      final log = HabitLog(
        habitId: habitId,
        date: date,
        status: HabitLogStatus.done,
      );

      expect(log.habitId, habitId);
      expect(log.date, date);
      expect(log.status, HabitLogStatus.done);
    });

    test('HabitLogStatus has three values', () {
      expect(HabitLogStatus.values.length, 3);
      expect(
        HabitLogStatus.values,
        containsAll([
          HabitLogStatus.done,
          HabitLogStatus.late,
          HabitLogStatus.missed,
        ]),
      );
    });
  });

  group('Collection entity', () {
    final collId = CollectionId('coll-uuid-001');
    final habitIds = [HabitId('h-1'), HabitId('h-2')];

    test('creates with valid fields', () {
      final coll = Collection(
        id: collId,
        name: NonEmptyString('Morning routine'),
        description: NonEmptyString('Start the day right'),
        habitIds: habitIds,
        isSystem: true,
        isActive: false,
      );

      expect(coll.id, collId);
      expect(coll.habitIds.length, 2);
      expect(coll.isSystem, isTrue);
      expect(coll.isActive, isFalse);
    });

    test('habitIds cannot be empty', () {
      expect(
        () => Collection(
          id: collId,
          name: NonEmptyString('Morning routine'),
          description: NonEmptyString('Start the day right'),
          habitIds: [],
          isSystem: true,
          isActive: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('UserScore entity', () {
    final userId = UserId('user-uuid-001');

    test('creates with valid fields', () {
      final score = UserScore(
        userId: userId,
        totalPoints: 1500,
        weeklyPoints: 120,
        currentLevel: Level.murid,
        weeklyRank: 3,
      );

      expect(score.userId, userId);
      expect(score.totalPoints, 1500);
      expect(score.currentLevel, Level.murid);
    });

    test('two scores with same fields are equal', () {
      final a = UserScore(
        userId: userId,
        totalPoints: 1500,
        weeklyPoints: 120,
        currentLevel: Level.murid,
        weeklyRank: 3,
      );
      final b = UserScore(
        userId: userId,
        totalPoints: 1500,
        weeklyPoints: 120,
        currentLevel: Level.murid,
        weeklyRank: 3,
      );
      expect(a, equals(b));
    });

    test('totalPoints cannot be negative', () {
      expect(
        () => UserScore(
          userId: userId,
          totalPoints: -1,
          weeklyPoints: 0,
          currentLevel: Level.aspirant,
          weeklyRank: 1,
        ),
        throwsArgumentError,
      );
    });

    test('weeklyRank must be positive', () {
      expect(
        () => UserScore(
          userId: userId,
          totalPoints: 0,
          weeklyPoints: 0,
          currentLevel: Level.aspirant,
          weeklyRank: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Notification entity', () {
    test('creates with valid fields', () {
      final scheduledAt = DateTime(2026, 4, 27, 8, 0);
      final notif = AppNotification(
        id: NonEmptyString('notif-uuid-001'),
        title: NonEmptyString('Heure de Fajr'),
        body: NonEmptyString('Il est temps de prier Fajr'),
        scheduledAt: scheduledAt,
        type: NotificationType.prayer,
      );

      expect(notif.title.value, 'Heure de Fajr');
      expect(notif.type, NotificationType.prayer);
    });

    test('two notifications with same fields are equal', () {
      final scheduledAt = DateTime(2026, 4, 27, 8, 0);
      final a = AppNotification(
        id: NonEmptyString('notif-uuid-001'),
        title: NonEmptyString('Heure de Fajr'),
        body: NonEmptyString('Il est temps de prier Fajr'),
        scheduledAt: scheduledAt,
        type: NotificationType.prayer,
      );
      final b = AppNotification(
        id: NonEmptyString('notif-uuid-001'),
        title: NonEmptyString('Heure de Fajr'),
        body: NonEmptyString('Il est temps de prier Fajr'),
        scheduledAt: scheduledAt,
        type: NotificationType.prayer,
      );
      expect(a, equals(b));
    });

    test('NotificationType has prayer and habit values', () {
      expect(
        NotificationType.values,
        containsAll([NotificationType.prayer, NotificationType.habit]),
      );
    });
  });

  group('DailyNiyyah entity', () {
    final userId = UserId('user-uuid-001');
    final today = DateTime(2026, 4, 28);

    test('creates with valid fields', () {
      final niyyah = DailyNiyyah(
        userId: userId,
        date: today,
        text: NonEmptyString("Aujourd'hui, je m'engage à prier à l'heure."),
      );

      expect(niyyah.userId, userId);
      expect(niyyah.date, today);
      expect(niyyah.text.value, "Aujourd'hui, je m'engage à prier à l'heure.");
    });

    test('two niyyahs with same fields are equal', () {
      final a = DailyNiyyah(
        userId: userId,
        date: today,
        text: NonEmptyString('Intention A'),
      );
      final b = DailyNiyyah(
        userId: userId,
        date: today,
        text: NonEmptyString('Intention A'),
      );
      expect(a, equals(b));
    });

    test('two niyyahs with different dates are not equal', () {
      final a = DailyNiyyah(
        userId: userId,
        date: DateTime(2026, 4, 28),
        text: NonEmptyString('Intention'),
      );
      final b = DailyNiyyah(
        userId: userId,
        date: DateTime(2026, 4, 27),
        text: NonEmptyString('Intention'),
      );
      expect(a, isNot(equals(b)));
    });
  });
}
