import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/constants/scoring_constants.dart';

/// Verrouille les barèmes de scoring (issue #6 — Phase 5).
///
/// Toute évolution d'un barème doit casser ce test : c'est la source de
/// vérité unique des points. Aucun magic number dans les use cases.
void main() {
  group('ScoringConstants', () {
    test('prière à l\'heure vaut 3 points', () {
      expect(ScoringConstants.prayerOnTimePoints, 3);
    });

    test('prière en retard / rattrapée vaut 1 point', () {
      expect(ScoringConstants.prayerLatePoints, 1);
    });

    test('prière manquée / en attente vaut 0 point', () {
      expect(ScoringConstants.prayerMissedPoints, 0);
    });

    test('habitude en retard vaut 1 point (statut "late")', () {
      expect(ScoringConstants.habitLatePoints, 1);
    });

    test('habitude manquée vaut 0 point', () {
      expect(ScoringConstants.habitMissedPoints, 0);
    });

    test('le score hebdomadaire couvre 7 jours', () {
      expect(ScoringConstants.weekLengthDays, 7);
    });
  });
}
