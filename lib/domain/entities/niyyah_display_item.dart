import 'package:murabbi_mobile/domain/entities/daily_niyyah.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_suggestion.dart';

/// Type union représentant ce qui est affiché dans la carte niyyah du dashboard.
///
/// - [UserNiyyah] : l'utilisateur a posé sa propre intention aujourd'hui.
/// - [SystemNiyyah] : fallback système (suggestion rotative ou constante).
sealed class NiyyahDisplayItem {
  const NiyyahDisplayItem();

  /// Texte à afficher dans l'UI.
  String get displayText;
}

/// Intention personnelle de l'utilisateur pour aujourd'hui.
class UserNiyyah extends NiyyahDisplayItem {
  final DailyNiyyah niyyah;

  const UserNiyyah(this.niyyah);

  @override
  String get displayText => niyyah.text.value;
}

/// Suggestion système (rotative ou fallback hardcodé).
class SystemNiyyah extends NiyyahDisplayItem {
  final String text;

  const SystemNiyyah(this.text);

  factory SystemNiyyah.fromSuggestion(NiyyahSuggestion s) =>
      SystemNiyyah(s.textFr);

  @override
  String get displayText => text;
}
