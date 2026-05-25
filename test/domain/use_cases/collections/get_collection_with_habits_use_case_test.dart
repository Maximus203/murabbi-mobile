import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/repositories/collection_repository.dart';
import 'package:murabbi_mobile/domain/repositories/habit_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/collections/get_collection_with_habits_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../../helpers/test_uuids.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late MockCollectionRepository mockCollectionRepo;
  late MockHabitRepository mockHabitRepo;

  final userId = UserId(kUserIdAlpha);
  final collectionId = CollectionId(kCollectionIdAlpha);

  final habit1 = Habit(
    id: HabitId(kHabitIdAlpha),
    name: NonEmptyString('Habit 1'),
    categoryId: CategoryId(kCategoryIdAlpha),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: {1},
    points: HabitPoints(5),
    isSystem: false,
  );

  final habit2 = Habit(
    id: HabitId(kHabitIdBeta),
    name: NonEmptyString('Habit 2'),
    categoryId: CategoryId(kCategoryIdAlpha),
    frequencyType: HabitFrequencyType.daily,
    frequency: 1,
    activeDays: {1},
    points: HabitPoints(3),
    isSystem: false,
  );

  final collection = Collection(
    id: collectionId,
    name: NonEmptyString('Morning routine'),
    description: NonEmptyString('Start the day right'),
    habitIds: [HabitId(kHabitIdAlpha), HabitId(kHabitIdBeta)],
    isSystem: false,
    isActive: true,
  );

  setUp(() {
    mockCollectionRepo = MockCollectionRepository();
    mockHabitRepo = MockHabitRepository();
    registerFallbackValue(CollectionId('fallback-coll-id'));
    registerFallbackValue(UserId('fallback-user-id'));
  });

  group('GetCollectionWithHabitsUseCase', () {
    late GetCollectionWithHabitsUseCase useCase;

    setUp(() {
      useCase = GetCollectionWithHabitsUseCase(
        collectionRepository: mockCollectionRepo,
        habitRepository: mockHabitRepo,
      );
    });

    test('retourne la collection et la liste de ses habitudes', () async {
      when(
        () => mockCollectionRepo.getCollections(userId),
      ).thenAnswer((_) async => [collection]);
      when(
        () => mockHabitRepo.getHabits(userId),
      ).thenAnswer((_) async => [habit1, habit2]);

      final result = await useCase(userId: userId, collectionId: collectionId);

      expect(result.collection, collection);
      expect(result.habits, containsAll([habit1, habit2]));
    });

    test(
      'filtre uniquement les habitudes appartenant à la collection',
      () async {
        final habit3 = Habit(
          id: HabitId(kHabitIdGamma),
          name: NonEmptyString('Habit 3'),
          categoryId: CategoryId(kCategoryIdAlpha),
          frequencyType: HabitFrequencyType.daily,
          frequency: 1,
          activeDays: {1},
          points: HabitPoints(2),
          isSystem: false,
        );

        when(
          () => mockCollectionRepo.getCollections(userId),
        ).thenAnswer((_) async => [collection]);
        when(
          () => mockHabitRepo.getHabits(userId),
        ).thenAnswer((_) async => [habit1, habit2, habit3]);

        final result = await useCase(
          userId: userId,
          collectionId: collectionId,
        );

        // habit3 n'est pas dans collection.habitIds → exclu
        expect(result.habits, hasLength(2));
        expect(result.habits, isNot(contains(habit3)));
      },
    );

    test("lève StateError si la collection n'est pas trouvée", () async {
      when(
        () => mockCollectionRepo.getCollections(userId),
      ).thenAnswer((_) async => []);

      expect(
        () => useCase(userId: userId, collectionId: collectionId),
        throwsStateError,
      );
    });

    test('retourne habitudes vides si aucune habitude ne correspond', () async {
      when(
        () => mockCollectionRepo.getCollections(userId),
      ).thenAnswer((_) async => [collection]);
      when(
        () => mockHabitRepo.getHabits(userId),
      ).thenAnswer((_) async => <Habit>[]);

      final result = await useCase.call(
        userId: userId,
        collectionId: collectionId,
      );

      expect(result.collection, collection);
      expect(result.habits, isEmpty);
    });
  });
}
