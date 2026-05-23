import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/habit_occurrence.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';

/// Provider du repository d'occurrences — injectable en test via override.
///
/// L'implémentation production est branchée dans `main.dart`.
/// Cf. MOB-007 — ADR-016 (providers legacy manuels, pas de codegen).
final occurrenceRepositoryProvider = Provider<OccurrenceRepository>((ref) {
  throw UnimplementedError(
    'occurrenceRepositoryProvider must be overridden in main() '
    'or in test with ProviderContainer(overrides: [...])',
  );
});

/// Occurrences du jour courant pour l'utilisateur connecté.
///
/// Auto-invalidé par [ValidateOccurrenceNotifier] et [SnoozeOccurrenceNotifier]
/// via `ref.invalidate(todayOccurrencesProvider)`.
///
/// Alimenté par [OccurrenceRepository.getTodayOccurrences].
final todayOccurrencesProvider = FutureProvider<List<HabitOccurrence>>((ref) {
  return ref.watch(occurrenceRepositoryProvider).getTodayOccurrences();
});

/// Occurrences en attente de validation dans la grace window.
///
/// Dérivé de [todayOccurrencesProvider] — filtre par
/// [OccurrenceStatus.awaitingValidation].
///
/// **Badge count** : la longueur de cette liste alimente le badge du
/// dashboard (HM-01) pour signaler les habitudes à valider.
///
/// Note : un provider synchrone dérivé d'un FutureProvider retourne
/// une liste vide tant que le Future n'est pas résolu.
final awaitingValidationProvider = Provider<List<HabitOccurrence>>((ref) {
  final asyncOccurrences = ref.watch(todayOccurrencesProvider);
  return asyncOccurrences.maybeWhen(
    data: (occurrences) => occurrences
        .where((o) => o.status == OccurrenceStatus.awaitingValidation)
        .toList(),
    orElse: () => [],
  );
});

/// Notifier pour la validation d'une occurrence (action `done`).
///
/// Après succès : invalide [todayOccurrencesProvider] pour déclencher
/// un re-fetch et mettre à jour le badge count.
final validateOccurrenceNotifierProvider =
    AsyncNotifierProvider<ValidateOccurrenceNotifier, void>(
  ValidateOccurrenceNotifier.new,
);

/// Notifier gérant la validation d'une occurrence habitude.
///
/// Expose une action [validate] qui :
/// 1. Passe l'état en [AsyncValue.loading].
/// 2. Appelle [OccurrenceRepository.validateOccurrence].
/// 3. Invalide [todayOccurrencesProvider] pour re-fetch le feed.
/// 4. En cas d'erreur, expose [AsyncValue.error] (l'UI peut afficher un snackbar).
class ValidateOccurrenceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Valide l'occurrence [occurrenceId] pour [userId].
  Future<void> validate(String occurrenceId, {required String userId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(occurrenceRepositoryProvider).validateOccurrence(
        occurrenceId: occurrenceId,
        userId: userId,
      );
      // Invalide le feed pour déclencher un re-fetch.
      ref.invalidate(todayOccurrencesProvider);
    });
  }
}
