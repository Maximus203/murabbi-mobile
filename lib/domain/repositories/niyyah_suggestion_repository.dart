import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';

abstract interface class NiyyahSuggestionRepository {
  /// Toutes les suggestions actives, triées par [NiyyahSuggestion.sortOrder].
  Future<List<NiyyahSuggestion>> getActiveSuggestions();
}
