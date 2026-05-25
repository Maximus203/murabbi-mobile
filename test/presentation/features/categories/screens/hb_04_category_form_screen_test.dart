import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/category_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/categories/screens/hb_04_category_form_screen.dart';
import 'package:murabbi_mobile/presentation/features/categories/widgets/category_tile.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
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

  Widget pumpable({Category? initial}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        categoryRepositoryProvider.overrideWithValue(
          InMemoryCategoryRepository(),
        ),
      ],
      child: MaterialApp(
        home: Hb04CategoryFormScreen(
          initialCategory: initial,
          onDone: () {},
          onCancel: () {},
        ),
      ),
    );
  }

  AppButton saveButton(WidgetTester tester) {
    return tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Enregistrer'),
    );
  }

  testWidgets('bouton Enregistrer désactivé si le nom est vide', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('bouton Enregistrer activé une fois le nom saisi', (
    tester,
  ) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Lecture');
    await tester.pumpAndSettle();

    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('la preview se met à jour en temps réel', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Méditation');
    await tester.pumpAndSettle();

    final tile = tester.widget<CategoryTile>(find.byType(CategoryTile));
    expect(tile.name, 'Méditation');
  });

  testWidgets('mode édition : champs pré-remplis', (tester) async {
    final category = Category(
      id: CategoryId('cat-x'),
      name: NonEmptyString('Lecture'),
      color: HexColor('#8B6F47'),
      icon: 'book-open',
      isSystem: false,
    );
    await tester.pumpWidget(pumpable(initial: category));
    await tester.pumpAndSettle();

    expect(find.text('Lecture'), findsWidgets);
    expect(find.text('Modifier la catégorie'), findsOneWidget);
  });

  testWidgets('bouton Supprimer absent en mode création', (tester) async {
    await tester.pumpWidget(pumpable());
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(AppButton, 'Supprimer la catégorie'),
      findsNothing,
    );
  });

  testWidgets('bouton Supprimer présent en mode édition', (tester) async {
    final category = Category(
      id: CategoryId('cat-x'),
      name: NonEmptyString('Lecture'),
      color: HexColor('#8B6F47'),
      icon: 'star',
      isSystem: false,
    );
    await tester.pumpWidget(pumpable(initial: category));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'Supprimer la catégorie'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.widgetWithText(AppButton, 'Supprimer la catégorie'),
      findsOneWidget,
    );
  });

  testWidgets('bouton Supprimer désactivé si catégorie système', (
    tester,
  ) async {
    final systemCategory = Category(
      id: CategoryId('cat-religion'),
      name: NonEmptyString('Religion'),
      color: HexColor('#8B6F47'),
      icon: 'moon-star',
      isSystem: true,
    );
    await tester.pumpWidget(pumpable(initial: systemCategory));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'Supprimer la catégorie'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final deleteBtn = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Supprimer la catégorie'),
    );
    expect(deleteBtn.onPressed, isNull);
  });
}
