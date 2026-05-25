import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/build_month_grid_use_case.dart';

void main() {
  const useCase = BuildMonthGridUseCase();

  test('mai 2026 commence un vendredi → 4 cellules vides en tête', () {
    // 1er mai 2026 = vendredi. Grille lundi-debut → index 4 (lun=0).
    final grid = useCase(year: 2026, month: 5);

    expect(grid.leadingBlanks, 4);
    expect(grid.days.length, 31);
    expect(grid.days.first.day, 1);
    expect(grid.days.last.day, 31);
  });

  test('février 2026 a 28 jours (année non bissextile)', () {
    final grid = useCase(year: 2026, month: 2);
    expect(grid.days.length, 28);
  });

  test('février 2024 a 29 jours (année bissextile)', () {
    final grid = useCase(year: 2024, month: 2);
    expect(grid.days.length, 29);
  });

  test('un mois commençant un lundi a 0 cellule vide', () {
    // juin 2026 : le 1er juin 2026 est un lundi.
    final grid = useCase(year: 2026, month: 6);
    expect(grid.leadingBlanks, 0);
  });

  test('chaque jour de la grille porte la bonne date complète', () {
    final grid = useCase(year: 2026, month: 5);
    expect(grid.days[14], DateTime(2026, 5, 15));
  });
}
