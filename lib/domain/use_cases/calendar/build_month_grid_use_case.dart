import 'package:equatable/equatable.dart';

/// Grille d'un mois pour CAL-01 — nombre de cellules vides en tête (pour
/// aligner le 1er du mois sous le bon jour de semaine) + liste ordonnée des
/// jours du mois.
class MonthGrid extends Equatable {
  /// Cellules vides à insérer avant le jour 1 (semaine débutant lundi).
  final int leadingBlanks;

  /// Tous les jours du mois, du 1er au dernier, comme [DateTime] à minuit.
  final List<DateTime> days;

  const MonthGrid({required this.leadingBlanks, required this.days});

  @override
  List<Object?> get props => [leadingBlanks, days];
}

/// CAL-01 — construit la grille d'un mois (issue #7).
///
/// Pure function : aucune dépendance externe. La semaine commence le lundi
/// (`DateTime.monday == 1` → index 0).
class BuildMonthGridUseCase {
  const BuildMonthGridUseCase();

  MonthGrid call({required int year, required int month}) {
    final first = DateTime(year, month);
    // `weekday` : lundi=1 .. dimanche=7 → index lundi-début 0..6.
    final leadingBlanks = first.weekday - DateTime.monday;
    // Le jour 0 du mois suivant = dernier jour du mois courant.
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = List<DateTime>.generate(
      daysInMonth,
      (i) => DateTime(year, month, i + 1),
    );
    return MonthGrid(leadingBlanks: leadingBlanks, days: days);
  }
}
