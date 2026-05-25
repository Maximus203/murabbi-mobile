import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/screens/hb_detail_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_log_history_tile.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_stat_card.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/heatmap_30.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

class _MockHabitRepo extends Mock implements HabitRepository {}

void main() {
  late _MockAuthRepo authRepo;
  late _MockHabitRepo habitRepo;

  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  Habit makeHabit() => Habit(
    id: HabitId('h1'),
    userId: UserId('user-001'),
    name: NonEmptyString('Lecture Coran'),
    categoryId: CategoryId('cat-religion'),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: const {1, 2, 3, 4, 5, 6, 7},
    points: HabitPoints(5),
    isSystem: false,
  );

  setUpAll(() {
    registerFallbackValue(UserId('fallback'));
    registerFallbackValue(HabitId('fallback'));
    registerFallbackValue(DateTime.utc(2026, 1, 1));
  });

  setUp(() {
    authRepo = _MockAuthRepo();
    habitRepo = _MockHabitRepo();
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => testUser);
    when(
      () => habitRepo.getHabits(any()),
    ).thenAnswer((_) async => [makeHabit()]);
    when(
      () => habitRepo.getLogsForHabit(
        habitId: any(named: 'habitId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => <HabitLog>[]);
    when(
      () => habitRepo.deleteHabit(any(), any()),
    ).thenAnswer((_) async {});
  });

  Widget pumpable({
    String habitId = 'h1',
    VoidCallback? onBack,
    void Function(String)? onEdit,
    VoidCallback? onDeleted,
  }) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        habitRepositoryProvider.overrideWithValue(habitRepo),
      ],
      child: MaterialApp(
        home: HbDetailScreen(
          habitId: habitId,
          onBack: onBack ?? () {},
          onEdit: onEdit ?? (_) {},
          onDeleted: onDeleted ?? () {},
        ),
      ),
    );
  }

  testWidgets('affiche le nom de l\'habitude dans le header', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.text('Lecture Coran'), findsOneWidget);
  });

  testWidgets('affiche 3 HabitStatCard', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.byType(HabitStatCard), findsNWidgets(3));
  });

  testWidgets('affiche le widget Heatmap30', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.byType(Heatmap30), findsOneWidget);
  });

  testWidgets('affiche au plus 7 lignes d\'historique', (tester) async {
    final logs = [
      for (var i = 0; i < 12; i++)
        HabitLog(
          habitId: HabitId('h1'),
          date: DateTime.now().toUtc().subtract(Duration(days: i)),
          status: HabitLogStatus.onTime,
        ),
    ];
    when(
      () => habitRepo.getLogsForHabit(
        habitId: any(named: 'habitId'),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => logs);

    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.byType(HabitLogHistoryTile), findsNWidgets(7));
  });

  testWidgets('loading state affiché pendant le chargement', (tester) async {
    await tester.pumpWidget(pumpable());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('error state avec bouton retry si chargement échoue', (
    tester,
  ) async {
    when(() => habitRepo.getHabits(any())).thenThrow(StateError('boom'));
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('bouton retour déclenche onBack', (tester) async {
    var backed = false;
    await tester.pumpWidget(pumpable(onBack: () => backed = true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(lu(LucideIcons.chevronLeft)));
    await tester.pumpAndSettle();
    expect(backed, isTrue);
  });
}
