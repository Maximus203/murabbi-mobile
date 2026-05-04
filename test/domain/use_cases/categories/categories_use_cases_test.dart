import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/repositories/category_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/categories/create_category_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/categories/get_categories_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository mockRepo;
  final userId = UserId('user-uuid-001');

  final testCategory = Category(
    id: CategoryId('cat-uuid-001'),
    name: NonEmptyString('Sport'),
    color: HexColor('#4A5568'),
    icon: 'activity',
    isSystem: false,
  );

  setUp(() {
    mockRepo = MockCategoryRepository();
    registerFallbackValue(testCategory);
  });

  group('GetCategoriesUseCase', () {
    late GetCategoriesUseCase useCase;

    setUp(() => useCase = GetCategoriesUseCase(mockRepo));

    test('calls repository.getCategories and returns list', () async {
      when(
        () => mockRepo.getCategories(userId),
      ).thenAnswer((_) async => [testCategory]);

      final result = await useCase(userId);

      expect(result, [testCategory]);
      verify(() => mockRepo.getCategories(userId)).called(1);
    });
  });

  group('CreateCategoryUseCase', () {
    late CreateCategoryUseCase useCase;

    setUp(() => useCase = CreateCategoryUseCase(mockRepo));

    test('calls repository.createCategory and returns category', () async {
      when(
        () => mockRepo.createCategory(userId: userId, category: testCategory),
      ).thenAnswer((_) async => testCategory);

      final result = await useCase(userId: userId, category: testCategory);

      expect(result, testCategory);
      verify(
        () => mockRepo.createCategory(userId: userId, category: testCategory),
      ).called(1);
    });
  });
}
