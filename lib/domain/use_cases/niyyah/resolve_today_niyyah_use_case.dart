import 'package:murabbi_mobile/domain/repositories/niyyah_repository.dart';
import 'package:murabbi_mobile/domain/repositories/niyyah_suggestion_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Résultat de [ResolveTodayNiyyahUseCase].
///
/// [isPersonal] = true → texte posé par l'utilisateur (éditable).
/// [isPersonal] = false → suggestion système en rotation.
class ResolvedNiyyah {
  final String text;
  final bool isPersonal;

  const ResolvedNiyyah({required this.text, required this.isPersonal});
}

/// Retourne la niyyah du jour : personnelle si l'utilisateur en a posé une,
/// sinon une suggestion système en rotation (dayOfYear % activeCount).
///
/// Le [referenceDate] est injecté pour faciliter les tests.
class ResolveTodayNiyyahUseCase {
  final NiyyahRepository _niyyahRepo;
  final NiyyahSuggestionRepository _suggestionRepo;

  const ResolveTodayNiyyahUseCase(this._niyyahRepo, this._suggestionRepo);

  Future<ResolvedNiyyah?> call({
    required UserId userId,
    required DateTime referenceDate,
  }) async {
    final personal = await _niyyahRepo.getTodayNiyyah(userId);
    if (personal != null) {
      return ResolvedNiyyah(text: personal.text.value, isPersonal: true);
    }

    final suggestions = await _suggestionRepo.getActiveSuggestions();
    if (suggestions.isEmpty) return null;

    final sorted = [...suggestions]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final idx = _dayOfYear(referenceDate) % sorted.length;
    return ResolvedNiyyah(text: sorted[idx].textFr, isPersonal: false);
  }

  int _dayOfYear(DateTime dt) =>
      dt.difference(DateTime(dt.year)).inDays + 1;
}
