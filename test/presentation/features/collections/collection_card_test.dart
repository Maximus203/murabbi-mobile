import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/collections/widgets/collection_card.dart';

Collection _collection({
  bool isSystem = false,
  bool isActive = false,
  int habits = 2,
}) => Collection(
  id: CollectionId('c-1'),
  name: NonEmptyString('Routine du matin'),
  description: NonEmptyString('Bien démarrer la journée'),
  habitIds: List.generate(habits, (i) => HabitId('h-$i')),
  isSystem: isSystem,
  isActive: isActive,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CollectionCard', () {
    testWidgets('affiche le nom, la description et le nombre d\'habitudes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CollectionCard(collection: _collection(), onTap: () {})),
      );

      expect(find.text('Routine du matin'), findsOneWidget);
      expect(find.text('Bien démarrer la journée'), findsOneWidget);
      expect(find.text('2 habitudes'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('affiche le badge Système pour une collection système', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CollectionCard(collection: _collection(isSystem: true), onTap: () {}),
        ),
      );

      expect(find.text('Système'), findsOneWidget);
    });

    testWidgets('affiche "Active" pour une collection active', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CollectionCard(collection: _collection(isActive: true), onTap: () {}),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('déclenche onTap au tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          CollectionCard(collection: _collection(), onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(CollectionCard));
      expect(tapped, true);
    });
  });
}
