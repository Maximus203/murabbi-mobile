import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/user_score_provider.dart';

/// Extension utilitaire pour invalider en un appel les caches de score
/// affichés sur le dashboard (HM-01) après toute mutation impactant le
/// total de points utilisateur (log d'habitude, log de prière, etc.).
///
/// Cf. issue #196 (M6) : `userScoreProvider` et `dashboardNotifierProvider`
/// restaient périmés jusqu'au prochain cold start, donnant une impression
/// de score figé après chaque validation.
///
/// Usage typique dans un notifier qui mute le score serveur :
/// ```dart
/// await ref.read(habitRepositoryProvider).logHabit(...);
/// ref.invalidateScoreCache();
/// ```
extension ScoreInvalidation on Ref {
  /// Invalide tous les providers exposant le score utilisateur. Le prochain
  /// `watch` rechargera depuis la source (Supabase via le repository).
  void invalidateScoreCache() {
    invalidate(userScoreProvider);
    invalidate(dashboardNotifierProvider);
  }
}
