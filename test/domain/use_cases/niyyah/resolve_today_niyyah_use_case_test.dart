import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_suggestion_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/niyyah/resolve_today_niyyah_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import '../../../helpers/test_uuids.dart';

class MockNiyyahRepo extends Mock implements NiyyahRepository {}

class MockSuggestionRepo extends Mock implements NiyyahSuggestionRepository {}

void main() {
  late MockNiyyahRepo niyyahRepo;
  late MockSuggestionRepo suggestionRepo;

  final userId = UserId(kUserIdAlpha);
  final today = DateTime(2026, 5, 25); // dayOfYear = 145

  final personalNiyyah = DailyNiyyah(
    userId: userId,
    date: today,
    text: NonEmptyString('Mon intention personnelle.'),
  );

  final suggestions = [
    const NiyyahSuggestion(
      id: kNiyyahSuggestionIdAlpha,
      textFr: 'Suggestion 0',
      sortOrder: 0,
    ),
    const NiyyahSuggestion(
      id: '11111111-1111-1111-1111-111111111102',
      textFr: 'Suggestion 1',
      sortOrder: 1,
    ),
    const NiyyahSuggestion(
      id: '11111111-1111-1111-1111-111111111103',
      textFr: 'Suggestion 2',
      sortOrder: 2,
    ),
  ];

  setUp(() {
    niyyahRepo = MockNiyyahRepo();
    suggestionRepo = MockSuggestionRepo();
  });

  ResolveTodayNiyyahUseCase buildUseCase() =>
      ResolveTodayNiyyahUseCase(niyyahRepo, suggestionRepo);

  group('ResolveTodayNiyyahUseCase — niyyah personnelle', () {
    test('retourne la niyyah personnelle quand elle existe', () async {
      when(
        () => niyyahRepo.getTodayNiyyah(userId),
      ).thenAnswer((_) async => personalNiyyah);

      final result = await buildUseCase().call(
        userId: userId,
        referenceDate: today,
      );

      expect(result, isNotNull);
      expect(result!.text, 'Mon intention personnelle.');
      expect(result.isPersonal, isTrue);
      verifyNever(() => suggestionRepo.getActiveSuggestions());
    });
  });

  group('ResolveTodayNiyyahUseCase — fallback suggestion', () {
    setUp(() {
      when(
        () => niyyahRepo.getTodayNiyyah(userId),
      ).thenAnswer((_) async => null);
      when(
        () => suggestionRepo.getActiveSuggestions(),
      ).thenAnswer((_) async => suggestions);
    });

    test('retourne une suggestion système quand aucune niyyah personnelle', () async {
      final result = await buildUseCase().call(
        userId: userId,
        referenceDate: today,
      );

      expect(result, isNotNull);
      expect(result!.isPersonal, isFalse);
    });

    test('rotation : dayOfYear 145 % 3 = index 1 → Suggestion 1', () async {
      // today = 2026-05-25 → dayOfYear = 145, 145 % 3 = 1
      final result = await buildUseCase().call(
        userId: userId,
        referenceDate: today,
      );

      expect(result!.text, 'Suggestion 1');
    });

    test('rotation : dayOfYear 1 % 3 = index 1 → Suggestion 1', () async {
      final jan1 = DateTime(2026, 1, 1); // dayOfYear = 1
      final result = await buildUseCase().call(
        userId: userId,
        referenceDate: jan1,
      );

      expect(result!.text, 'Suggestion 1');
    });

    test('rotation : dayOfYear 3 % 3 = index 0 → Suggestion 0', () async {
      final jan3 = DateTime(2026, 1, 3); // dayOfYear = 3
      final result = await buildUseCase().call(
        userId: userId,
        referenceDate: jan3,
      );

      expect(result!.text, 'Suggestion 0');
    });

    test('retourne null quand aucune suggestion active', () async {
      when(
        () => suggestionRepo.getActiveSuggestions(),
      ).thenAnswer((_) async => []);

      final result = await buildUseCase().call(
        userId: userId,
        referenceDate: today,
      );

      expect(result, isNull);
    });
  });
}
