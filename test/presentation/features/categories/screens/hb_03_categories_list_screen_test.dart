import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/habit_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/categories/screens/hb_03_categories_list_screen.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';
import '../../../../helpers/in_memory_repositories.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo authRepo;

  final testUser = User(
    id: UserId('user-001'),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime.utc(2026, 1, 1),
    level: Level.aspirant,
  );

  setUp(() {
    authRepo = _MockAuthRepo();
    when(
      () => authRepo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => authRepo.getCurrentUser()).thenAnswer((_) async => testUser);
  });

  Category userCategory(String id, String name) => Category(
    id: CategoryId(id),
    name: NonEmptyString(name),
    color: HexColor('#8B6F47'),
    icon: 'star',
    isSystem: false,
  );

  Widget pumpable({InMemoryCategoryRepository? repo}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        habitRepositoryProvider.overrideWithValue(InMemoryHabitRepository()),
        categoryRepositoryProvider.overrideWithValue(
          repo ?? InMemoryCategoryRepository(),
        ),
      ],
      child: MaterialApp(
        home: Hb03CategoriesListScreen(onCreate: () {}, onEdit: (_) {}),
      ),
    );
  }

  testWidgets('affiche les sections système et "Mes catégories"', (
    tester,
  ) async {
    final repo = InMemoryCategoryRepository();
    await repo.createCategory(
      userId: testUser.id,
      category: userCategory('cat-x', 'Lecture'),
    );
    await tester.pumpWidget(pumpable(repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('CATÉGORIES SYSTÈME'), findsOneWidget);
    expect(find.text('MES CATÉGORIES'), findsOneWidget);
    expect(find.text('Lecture'), findsOneWidget);
  });

  testWidgets('empty state visible quand aucune catégorie utilisateur', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    expect(find.text('Aucune catégorie personnelle'), findsOneWidget);
    expect(find.text('Créer une catégorie'), findsOneWidget);
  });

  testWidgets('swipe-delete sur catégorie user affiche le dialog', (
    tester,
  ) async {
    final repo = InMemoryCategoryRepository();
    await repo.createCategory(
      userId: testUser.id,
      category: userCategory('cat-x', 'Lecture'),
    );
    await tester.pumpWidget(pumpable(repo: repo));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Lecture'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.byType(AppDialog), findsOneWidget);
    expect(find.text('Supprimer la catégorie ?'), findsOneWidget);
  });

  testWidgets('pull-to-refresh recharge la liste', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    await tester.fling(
      find.text('CATÉGORIES SYSTÈME'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    // La liste reste affichée après le refresh — pas de crash.
    expect(find.text('CATÉGORIES SYSTÈME'), findsOneWidget);
  });
}
