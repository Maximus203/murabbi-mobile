import 'package:murabbi_mobile/domain/entities/niyyah_display_item.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_suggestion_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Résout la niyyah à afficher pour aujourd'hui :
/// 1. Niyyah personnelle de l'utilisateur si elle existe.
/// 2. Sinon, suggestion système rotative (`dayOfYear % suggestions.length`).
/// 3. Si aucune suggestion disponible, fallback hardcodé.
class ResolveTodayNiyyahUseCase {
  static const _fallback =
      'Je cherche à plaire à Allah dans tout ce que je fais aujourd\'hui.';

  final NiyyahRepository _niyyahRepository;
  final NiyyahSuggestionRepository _suggestionRepository;

  const ResolveTodayNiyyahUseCase({
    required NiyyahRepository niyyahRepository,
    required NiyyahSuggestionRepository suggestionRepository,
  })  : _niyyahRepository = niyyahRepository,
        _suggestionRepository = suggestionRepository;

  Future<NiyyahDisplayItem> call(
    UserId userId, {
    required DateTime referenceDate,
  }) async {
    final niyyah = await _niyyahRepository.getTodayNiyyah(userId);
    if (niyyah != null) return UserNiyyah(niyyah);

    final suggestions = await _suggestionRepository.getActiveSuggestions();
    if (suggestions.isEmpty) return const SystemNiyyah(_fallback);

    final dayOfYear = _dayOfYear(referenceDate);
    final index = dayOfYear % suggestions.length;
    return SystemNiyyah.fromSuggestion(suggestions[index]);
  }

  /// Numéro du jour dans l'année (1-based).
  int _dayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year);
    return date.difference(startOfYear).inDays + 1;
  }
}
