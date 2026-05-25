import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/collections/widgets/collection_card.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';

Collection _collection({
  bool isSystem = false,
  bool isActive = false,
  int habits = 3,
}) => Collection(
  id: CollectionId('c-1'),
  name: NonEmptyString('Routine du matin'),
  description: NonEmptyString('Bien démarrer la journée'),
  habitIds: List.generate(habits, (i) => HabitId('h-$i')),
  isSystem: isSystem,
  isActive: isActive,
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('CollectionCard', () {
    testWidgets('affiche le nom et la description', (tester) async {
      await tester.pumpWidget(
        _wrap(CollectionCard(collection: _collection(), onTap: () {})),
      );

      expect(find.text('Routine du matin'), findsOneWidget);
      expect(find.text('Bien démarrer la journée'), findsOneWidget);
    });

    testWidgets('affiche le badge N HABITUDES', (tester) async {
      await tester.pumpWidget(
        _wrap(CollectionCard(collection: _collection(habits: 4), onTap: () {})),
      );

      expect(find.text('4 HABITUDES'), findsOneWidget);
    });

    testWidgets('badge catégorie affiché quand categoryName fourni', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CollectionCard(
            collection: _collection(),
            onTap: () {},
            categoryName: 'Religion',
            categoryColor: AppColors.categoryReligion,
          ),
        ),
      );

      expect(find.text('RELIGION'), findsOneWidget);
    });

    testWidgets('badge catégorie absent quand categoryName null', (tester) async {
      await tester.pumpWidget(
        _wrap(CollectionCard(collection: _collection(), onTap: () {})),
      );

      // Aucune chaîne en majuscules ressemblant à un badge catégorie.
      expect(find.text('RELIGION'), findsNothing);
      expect(find.text('SANTÉ'), findsNothing);
    });

    testWidgets('badge PTS/JOUR affiché quand ptsPerDay fourni', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CollectionCard(
            collection: _collection(),
            onTap: () {},
            ptsPerDay: 12,
          ),
        ),
      );

      expect(find.text('12 PTS/JOUR'), findsOneWidget);
    });

    testWidgets('badge PTS/JOUR absent quand ptsPerDay null', (tester) async {
      await tester.pumpWidget(
        _wrap(CollectionCard(collection: _collection(), onTap: () {})),
      );

      expect(find.textContaining('PTS/JOUR'), findsNothing);
    });

    testWidgets('bouton Activer affiché quand onActivate fourni', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CollectionCard(
            collection: _collection(isActive: false),
            onTap: () {},
            onActivate: () {},
          ),
        ),
      );

      expect(find.text('Activer'), findsOneWidget);
      expect(find.text('Activée'), findsNothing);
    });

    testWidgets('badge Activée affiché quand collection active sans onActivate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CollectionCard(
            collection: _collection(isActive: true),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Activée'), findsOneWidget);
      expect(find.text('Activer'), findsNothing);
    });

    testWidgets('onTap déclenché au tap sur la carte', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          CollectionCard(
            collection: _collection(),
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(CollectionCard));
      expect(tapped, isTrue);
    });

    testWidgets('onActivate déclenché au tap sur le bouton Activer', (
      tester,
    ) async {
      var activated = false;
      await tester.pumpWidget(
        _wrap(
          CollectionCard(
            collection: _collection(isActive: false),
            onTap: () {},
            onActivate: () => activated = true,
          ),
        ),
      );

      await tester.tap(find.text('Activer'));
      expect(activated, isTrue);
    });
  });
}
