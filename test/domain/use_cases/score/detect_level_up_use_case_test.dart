import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/use_cases/score/detect_level_up_use_case.dart';

void main() {
  const useCase = DetectLevelUpUseCase();

  test('returns null when total points stay within the same level', () {
    expect(useCase(previousTotal: 100, newTotal: 500), isNull);
  });

  test('returns the new level when a threshold is crossed', () {
    // aspirant (0) -> murid (10000)
    expect(useCase(previousTotal: 9990, newTotal: 10010), Level.murid);
  });

  test('returns the new level when exactly landing on the threshold', () {
    expect(useCase(previousTotal: 9999, newTotal: 10000), Level.murid);
  });

  test(
    'returns the highest level reached when several thresholds are jumped',
    () {
      // aspirant -> salik (skips murid) — on annonce le palier atteint le + haut
      expect(useCase(previousTotal: 0, newTotal: 35000), Level.salik);
    },
  );

  test('returns null when points decrease', () {
    expect(useCase(previousTotal: 20000, newTotal: 5000), isNull);
  });

  test('returns null when already at max level', () {
    expect(useCase(previousTotal: 300000, newTotal: 400000), isNull);
  });
}
