import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';
import '../../helpers/test_uuids.dart';

void main() {
  group('NiyyahSuggestion entity', () {
    test('creates with required fields only', () {
      const suggestion = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Je cherche à plaire à Allah dans tout ce que je fais.',
        sortOrder: 0,
      );
      expect(suggestion.id, kNiyyahSuggestionIdAlpha);
      expect(
        suggestion.textFr,
        'Je cherche à plaire à Allah dans tout ce que je fais.',
      );
      expect(suggestion.textAr, isNull);
      expect(suggestion.sortOrder, 0);
      expect(suggestion.active, isTrue);
    });

    test('creates with optional textAr', () {
      const suggestion = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Je cherche à plaire à Allah.',
        textAr: 'أبتغي رضا الله فيما أفعل.',
        sortOrder: 0,
      );
      expect(suggestion.textAr, isNotNull);
    });

    test('active defaults to true', () {
      const suggestion = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention.',
        sortOrder: 1,
      );
      expect(suggestion.active, isTrue);
    });

    test('active can be set to false (désactivée)', () {
      const suggestion = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention archivée.',
        sortOrder: 9,
        active: false,
      );
      expect(suggestion.active, isFalse);
    });

    test('two suggestions with same fields are equal', () {
      const a = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention.',
        sortOrder: 0,
      );
      const b = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention.',
        sortOrder: 0,
      );
      expect(a, equals(b));
    });

    test('different sortOrder → not equal', () {
      const a = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention.',
        sortOrder: 0,
      );
      const b = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention.',
        sortOrder: 1,
      );
      expect(a, isNot(equals(b)));
    });

    test('active participates in equality', () {
      const active = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention.',
        sortOrder: 0,
      );
      const inactive = NiyyahSuggestion(
        id: kNiyyahSuggestionIdAlpha,
        textFr: 'Intention.',
        sortOrder: 0,
        active: false,
      );
      expect(active, isNot(equals(inactive)));
    });
  });
}
