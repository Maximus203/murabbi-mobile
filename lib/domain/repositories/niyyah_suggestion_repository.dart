import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';

abstract interface class NiyyahSuggestionRepository {
  Future<List<NiyyahSuggestion>> getActiveSuggestions();
}
