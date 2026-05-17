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
import 'package:murabbi_mobile/presentation/features/collections/screens/co_detail_collection_screen.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late MockCollectionRepository mockRepo;

  final userId = UserId('user-uuid-001');
  final testUser = User(
    id: userId,
    email: NonEmptyString('test@test.com'),
    pseudo: Pseudonym('TestUser'),
    createdAt: DateTime(2024),
    level: Level.aspirant,
  );

  final inactive = Collection(
    id: CollectionId('coll-1'),
    name: NonEmptyString('Routine matinale'),
    description: NonEmptyString('Commencer la journée'),
    habitIds: [HabitId('h-1')],
    isSystem: false,
    isActive: false,
  );

  final active = Collection(
    id: CollectionId('coll-2'),
    name: NonEmptyString('Sport hebdo'),
    description: NonEmptyString('Activité physique'),
    habitIds: [HabitId('h-2')],
    isSystem: false,
    isActive: true,
  );

  setUp(() {
    mockRepo = MockCollectionRepository();
    registerFallbackValue(CollectionId('fallback'));
    registerFallbackValue(userId);
  });

  Widget buildSut(Collection collection) {
    when(() => mockRepo.getCollections(any()))
        .thenAnswer((_) async => [inactive, active]);

    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        collectionRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: CoDetailCollectionScreen(
          collection: collection,
          onBack: () {},
        ),
      ),
    );
  }

  testWidgets('affiche le nom et la description de la collection', (
    tester,
  ) async {
    await tester.pumpWidget(buildSut(inactive));
    await tester.pumpAndSettle();

    expect(find.text('Routine matinale'), findsWidgets);
    expect(find.text('Commencer la journée'), findsOneWidget);
  });

  testWidgets('affiche bouton Activer si collection inactive', (tester) async {
    await tester.pumpWidget(buildSut(inactive));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_activate')), findsOneWidget);
    expect(find.byKey(const Key('btn_deactivate')), findsNothing);
  });

  testWidgets('affiche bouton Désactiver si collection active', (tester) async {
    await tester.pumpWidget(buildSut(active));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_deactivate')), findsOneWidget);
    expect(find.byKey(const Key('btn_activate')), findsNothing);
  });

  testWidgets('tap Activer appelle activateCollection', (tester) async {
    when(
      () => mockRepo.activateCollection(
        userId: any(named: 'userId'),
        collectionId: any(named: 'collectionId'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(buildSut(inactive));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_activate')));
    await tester.pumpAndSettle();

    verify(
      () => mockRepo.activateCollection(
        userId: any(named: 'userId'),
        collectionId: any(named: 'collectionId'),
      ),
    ).called(1);
  });
}
