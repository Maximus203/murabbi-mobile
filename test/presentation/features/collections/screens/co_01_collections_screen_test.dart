import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/collection_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/collections/screens/co_01_collections_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepo;

  final testUser = User(
    id: UserId('user-uuid-001'),
    email: NonEmptyString('test@test.com'),
    pseudo: Pseudonym('TestUser'),
    createdAt: DateTime(2024),
    level: Level.aspirant,
  );

  final collection1 = Collection(
    id: CollectionId('coll-1'),
    name: NonEmptyString('Routine matinale'),
    description: NonEmptyString('Commencer la journée'),
    habitIds: [HabitId('h-1')],
    isSystem: true,
    isActive: false,
  );

  final collection2 = Collection(
    id: CollectionId('coll-2'),
    name: NonEmptyString('Sport hebdo'),
    description: NonEmptyString('Activité physique'),
    habitIds: [HabitId('h-2'), HabitId('h-3')],
    isSystem: false,
    isActive: true,
  );

  setUp(() {
    mockRepo = MockCollectionRepository();
    registerFallbackValue(CollectionId('fallback'));
    registerFallbackValue(UserId('fallback-user'));
    registerFallbackValue(collection1);
  });

  Widget _buildSut({
    required List<Collection> collections,
    VoidCallback? onCreate,
    void Function(Collection)? onTap,
  }) {
    when(() => mockRepo.getCollections(any())).thenAnswer(
      (_) async => collections,
    );
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        collectionRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: Co01CollectionsScreen(
          onCreate: onCreate ?? () {},
          onTap: onTap ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('affiche la liste des collections', (tester) async {
    await tester.pumpWidget(
      _buildSut(collections: [collection1, collection2]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Routine matinale'), findsOneWidget);
    expect(find.text('Sport hebdo'), findsOneWidget);
  });

  testWidgets('affiche empty state si aucune collection', (tester) async {
    await tester.pumpWidget(_buildSut(collections: []));
    await tester.pumpAndSettle();

    expect(find.text('Aucune collection'), findsOneWidget);
  });

  testWidgets('bouton Nouvelle collection appelle onCreate', (tester) async {
    var called = false;
    await tester.pumpWidget(
      _buildSut(collections: [], onCreate: () => called = true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle collection').first);
    expect(called, isTrue);
  });

  testWidgets('tap sur une collection appelle onTap', (tester) async {
    Collection? tapped;
    await tester.pumpWidget(
      _buildSut(
        collections: [collection1],
        onTap: (c) => tapped = c,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Routine matinale'));
    expect(tapped, equals(collection1));
  });
}
