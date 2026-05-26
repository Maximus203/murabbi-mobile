import 'package:equatable/equatable.dart';

/// Suggestion d'intention quotidienne gérée par l'admin (table `niyyah_suggestions`).
///
/// Utilisée comme fallback par [ResolveTodayNiyyahUseCase] quand l'utilisateur
/// n'a pas posé sa propre niyyah. Rotation : `sortOrder % activeCount` basé
/// sur le jour de l'année.
class NiyyahSuggestion extends Equatable {
  /// UUID Supabase (gen_random_uuid()).
  final String id;

  final String textFr;

  /// Texte arabe optionnel (V1 : non affiché si null).
  final String? textAr;

  /// Position dans la rotation (0-based, UNIQUE en base).
  final int sortOrder;

  /// false = exclue de la rotation (archivée par l'admin).
  final bool active;

  const NiyyahSuggestion({
    required this.id,
    required this.textFr,
    this.textAr,
    required this.sortOrder,
    this.active = true,
  });

  @override
  List<Object?> get props => [id, textFr, textAr, sortOrder, active];
}
