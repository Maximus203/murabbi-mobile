import 'package:equatable/equatable.dart';

/// Suggestion d'intention quotidienne système — fallback affiché quand
/// l'utilisateur n'a pas posé sa propre niyyah pour la journée.
///
/// Rotation côté client : `suggestions[dayOfYear % suggestions.length]`
/// La sélection utilise [sortOrder] comme index stable.
class NiyyahSuggestion extends Equatable {
  final String id;
  final String textFr;
  final String? textAr;

  /// Index de rotation (0-based, UNIQUE en base).
  final int sortOrder;

  final bool active;

  const NiyyahSuggestion({
    required this.id,
    required this.textFr,
    this.textAr,
    required this.sortOrder,
    required this.active,
  });

  @override
  List<Object?> get props => [id, textFr, textAr, sortOrder, active];
}
