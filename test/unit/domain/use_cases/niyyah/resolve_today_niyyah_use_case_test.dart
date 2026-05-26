import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_display_item.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_suggestion_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/niyyah/resolve_today_niyyah_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class _MockNiyyahRepository extends Mock implements NiyyahRepository {}

class _MockNiyyahSuggestionRepository extends Mock
    implements NiyyahSuggestionRepository {}

void main() {
  late _MockNiyyahRepository niyyahRepo;
  late _MockNiyyahSuggestionRepository suggestionRepo;
  late ResolveTodayNiyyahUseCase useCase;

  final userId = UserId('user-abc');

  NiyyahSuggestion makeSuggestion(int order, String text) => NiyyahSuggestion(
        id: 'sug-$order',
        textFr: text,
        sortOrder: order,
        active: true,
      );

  setUp(() {
    niyyahRepo = _MockNiyyahRepository();
    suggestionRepo = _MockNiyyahSuggestionRepository();
    useCase = ResolveTodayNiyyahUseCase(
      niyyahRepository: niyyahRepo,
      suggestionRepository: suggestionRepo,
    );
  });

  group('ResolveTodayNiyyahUseCase', () {
    test('retourne UserNiyyah si l\'utilisateur a une niyyah aujourd\'hui',
        () async {
      final niyyah = DailyNiyyah(
        userId: userId,
        date: DateTime(2026, 5, 25),
        text: NonEmptyString('Bismillah'),
      );
      when(() => niyyahRepo.getTodayNiyyah(userId))
          .thenAnswer((_) async => niyyah);

      final result = await useCase(userId, referenceDate: DateTime(2026, 5, 25));

      expect(result, isA<UserNiyyah>());
      expect((result as UserNiyyah).niyyah, niyyah);
      verifyNever(() => suggestionRepo.getActiveSuggestions());
    });

    test('retourne SystemNiyyah avec rotation si pas de niyyah personnelle',
        () async {
      when(() => niyyahRepo.getTodayNiyyah(userId)).thenAnswer((_) async => null);
      when(() => suggestionRepo.getActiveSuggestions()).thenAnswer(
        (_) async => List.generate(
          10,
          (i) => makeSuggestion(i, 'Intention $i'),
        ),
      );
      // dayOfYear pour le 25/05/2026 = 145 → 145 % 10 = 5
      final result = await useCase(userId, referenceDate: DateTime(2026, 5, 25));

      expect(result, isA<SystemNiyyah>());
      expect((result as SystemNiyyah).displayText, 'Intention 5');
    });

    test('retourne SystemNiyyah fallback si liste de suggestions vide',
        () async {
      when(() => niyyahRepo.getTodayNiyyah(userId)).thenAnswer((_) async => null);
      when(() => suggestionRepo.getActiveSuggestions())
          .thenAnswer((_) async => []);

      final result = await useCase(userId, referenceDate: DateTime(2026, 5, 25));

      expect(result, isA<SystemNiyyah>());
      expect(
        (result as SystemNiyyah).displayText,
        isNotEmpty,
      );
    });

    test('rotation correcte avec 3 suggestions sur jours différents', () async {
      when(() => niyyahRepo.getTodayNiyyah(userId)).thenAnswer((_) async => null);
      final suggestions = [
        makeSuggestion(0, 'A'),
        makeSuggestion(1, 'B'),
        makeSuggestion(2, 'C'),
      ];
      when(() => suggestionRepo.getActiveSuggestions())
          .thenAnswer((_) async => suggestions);

      // dayOfYear(2026-01-01) = 1 → 1 % 3 = 1 → 'B'
      final r1 =
          await useCase(userId, referenceDate: DateTime(2026, 1, 1));
      expect((r1 as SystemNiyyah).displayText, 'B');

      // dayOfYear(2026-01-03) = 3 → 3 % 3 = 0 → 'A'
      final r2 =
          await useCase(userId, referenceDate: DateTime(2026, 1, 3));
      expect((r2 as SystemNiyyah).displayText, 'A');
    });
  });
}
