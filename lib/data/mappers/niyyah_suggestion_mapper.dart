import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';

/// Convertit une row `niyyah_suggestions` en [NiyyahSuggestion].
///
/// Colonnes attendues : `id`, `text_fr`, `text_ar`, `sort_order`, `active`.
class NiyyahSuggestionMapper {
  const NiyyahSuggestionMapper._();

  static NiyyahSuggestion fromRow(Map<String, dynamic> row) {
    return NiyyahSuggestion(
      id: row['id'] as String,
      textFr: row['text_fr'] as String,
      textAr: row['text_ar'] as String?,
      sortOrder: row['sort_order'] as int,
      active: (row['active'] as bool?) ?? true,
    );
  }
}
