import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/prayer_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/calendar/screens/cal_01_calendar_screen.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPrayerRepository extends Mock implements PrayerRepository {}

class _MockHabitRepository extends Mock implements HabitRepository {}

final _user = User(
  id: UserId('user-1'),
  pseudo: Pseudonym('Cherif'),
  email: NonEmptyString('cherif@example.com'),
  createdAt: DateTime(2026, 1, 1),
  level: Level.aspirant,
);

void main() {
  late _MockAuthRepository auth;
  late _MockPrayerRepository prayer;
  late _MockHabitRepository habit;

  setUpAll(() {
    registerFallbackValue(UserId('user-1'));
    registerFallbackValue(HabitId('habit-1'));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    auth = _MockAuthRepository();
    prayer = _MockPrayerRepository();
    habit = _MockHabitRepository();
    when(
      () => auth.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => auth.getCurrentUser()).thenAnswer((_) async => _user);
    when(() => habit.getHabits(any())).thenAnswer((_) async => <Habit>[]);
  });

  PrayerDay dayOf(DateTime date) => PrayerDay(
    userId: _user.id,
    date: date,
    fajr: PrayerStatus.onTime,
    dhuhr: PrayerStatus.onTime,
    asr: PrayerStatus.onTime,
    maghrib: PrayerStatus.onTime,
    isha: PrayerStatus.missed,
  );

  Widget wrap() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        prayerRepositoryProvider.overrideWithValue(prayer),
        habitRepositoryProvider.overrideWithValue(habit),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Cal01CalendarScreen(onBack: () {}),
      ),
    );
  }

  testWidgets('renders the month nav, filter tabs and a colored grid', (
    tester,
  ) async {
    when(
      () => prayer.getPrayerHistory(
        userId: any(named: 'userId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => [dayOf(DateTime(2026, 5, 10))]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Calendrier'), findsOneWidget);
    expect(find.text('Tout'), findsOneWidget);
    expect(find.text('Salat'), findsOneWidget);
    expect(find.text('Habitudes'), findsOneWidget);
  });

  testWidgets('shows the empty state when no activity in the month', (
    tester,
  ) async {
    when(
      () => prayer.getPrayerHistory(
        userId: any(named: 'userId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => <PrayerDay>[]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Aucune activité ce mois-ci'), findsOneWidget);
  });

  testWidgets('selecting a day shows its stats card', (tester) async {
    when(
      () => prayer.getPrayerHistory(
        userId: any(named: 'userId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => [dayOf(DateTime(2026, 5, 10))]);
    when(
      () => habit.getLogsForHabit(
        habitId: any(named: 'habitId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => <HabitLog>[]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Le jour 10 (avec données) est affiché — on tape dessus.
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();

    expect(find.text('Prières validées'), findsOneWidget);
    expect(find.text('Complétion'), findsOneWidget);
  });
}
