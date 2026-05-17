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
import 'package:murabbi_mobile/presentation/features/collections/screens/co_02_create_collection_screen.dart';
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

  setUp(() {
    mockRepo = MockCollectionRepository();
    registerFallbackValue(UserId('fallback-user'));
    registerFallbackValue(CollectionId('fallback-coll'));
    registerFallbackValue(
      Collection(
        id: CollectionId('fallback-coll'),
        name: NonEmptyString('fallback'),
        description: NonEmptyString('fallback'),
        habitIds: [HabitId('placeholder')],
        isSystem: false,
        isActive: false,
      ),
    );
  });

  Widget _buildSut({VoidCallback? onCreated, VoidCallback? onCancel}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        collectionRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: Co02CreateCollectionScreen(
          onCreated: onCreated ?? () {},
          onCancel: onCancel ?? () {},
        ),
      ),
    );
  }

  testWidgets('affiche les champs nom et description', (tester) async {
    await tester.pumpWidget(_buildSut());
    expect(find.byKey(const Key('field_name')), findsOneWidget);
    expect(find.byKey(const Key('field_description')), findsOneWidget);
  });

  testWidgets('erreur si nom vide à la soumission', (tester) async {
    await tester.pumpWidget(_buildSut());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom est requis.'), findsOneWidget);
  });

  testWidgets('appelle createCollection et onCreated si formulaire valide', (
    tester,
  ) async {
    when(
      () => mockRepo.createCollection(
        userId: any(named: 'userId'),
        collection: any(named: 'collection'),
      ),
    ).thenAnswer((_) async => Collection(
          id: CollectionId('new-coll'),
          name: NonEmptyString('Test'),
          description: NonEmptyString('Desc'),
          habitIds: [HabitId('placeholder')],
          isSystem: false,
          isActive: false,
        ));

    // getCollections est appelé par le notifier après create
    when(() => mockRepo.getCollections(any())).thenAnswer((_) async => []);

    var created = false;
    await tester.pumpWidget(_buildSut(onCreated: () => created = true));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('field_name')), 'Test');
    await tester.enterText(find.byKey(const Key('field_description')), 'Desc');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(created, isTrue);
    verify(
      () => mockRepo.createCollection(
        userId: any(named: 'userId'),
        collection: any(named: 'collection'),
      ),
    ).called(1);
  });
}
