import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';

/// Libellés FR affichables des niveaux + progression vers le palier suivant
/// (issue #6, Phase 5 — HM-01 score card).
void main() {
  group('Level.label', () {
    test('chaque niveau a un libellé FR capitalisé', () {
      expect(Level.aspirant.label, 'Aspirant');
      expect(Level.murid.label, 'Murīd');
      expect(Level.salik.label, 'Sālik');
      expect(Level.mujahid.label, 'Mujāhid');
      expect(Level.wali.label, 'Walī');
      expect(Level.murabbi.label, 'Murabbī');
    });
  });

  group('Level.nextLevel', () {
    test('renvoie le palier suivant', () {
      expect(Level.aspirant.nextLevel, Level.murid);
      expect(Level.wali.nextLevel, Level.murabbi);
    });

    test('le dernier niveau n\'a pas de suivant', () {
      expect(Level.murabbi.nextLevel, isNull);
    });
  });

  group('Level.progressToNext', () {
    test('progression 0 au seuil d\'entrée du niveau', () {
      expect(Level.aspirant.progressToNext(0), 0.0);
    });

    test('progression 0.5 à mi-chemin du palier suivant', () {
      // aspirant 0 → murid 10000 : 5000 ⇒ 50%
      expect(Level.aspirant.progressToNext(5000), 0.5);
    });

    test('progression 1.0 pour le dernier niveau (pas de palier suivant)', () {
      expect(Level.murabbi.progressToNext(999999), 1.0);
    });

    test('progression clampée à [0,1]', () {
      expect(Level.aspirant.progressToNext(999999), 1.0);
      expect(Level.murid.progressToNext(0), 0.0);
    });
  });
}
