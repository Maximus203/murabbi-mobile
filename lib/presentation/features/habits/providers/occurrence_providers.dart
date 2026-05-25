import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/habit_occurrence.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/repositories/occurrence_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/alerts/validate_occurrence_use_case.dart';

// ─── Provider du repository ──────────────────────────────────────────────────

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

// ─── Providers feed habitudes (MOB-007) ─────────────────────────────────────

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
      await ref
          .read(occurrenceRepositoryProvider)
          .validateOccurrence(occurrenceId: occurrenceId, userId: userId);
      // Invalide le feed pour déclencher un re-fetch.
      ref.invalidate(todayOccurrencesProvider);
    });
  }
}

// ─── Provider use case — anti-double-tap (BUG-003) ───────────────────────────

/// Provider du [ValidateOccurrenceUseCase] — injectable pour les tests.
final validateOccurrenceUseCaseProvider = Provider<ValidateOccurrenceUseCase>((
  ref,
) {
  return ValidateOccurrenceUseCase(ref.read(occurrenceRepositoryProvider));
});

/// État d'une validation d'occurrence en cours.
///
/// Utilise un `AsyncNotifier` familial (un provider par `occurrenceId`) pour
/// que chaque bouton « Valider » ait son propre état de chargement, sans
/// affecter les autres.
///
/// Implémente le guard anti-double-tap (BUG-003) :
/// - Si [state] est `AsyncLoading` → les appels suivants à [validate] sont
///   silencieusement ignorés.
/// - L'idempotency côté domaine est garantie par [ValidateOccurrenceUseCase]
///   (retourne l'occurrence `done` sans ré-écrire si déjà validée).
class OccurrenceValidationNotifier
    extends AutoDisposeFamilyAsyncNotifier<Occurrence?, String> {
  @override
  Future<Occurrence?> build(String occurrenceId) async {
    // État initial : null (aucune validation en cours)
    return null;
  }

  /// Valide l'occurrence identifiée par [occurrenceId] (la clé du provider).
  ///
  /// [source] désigne l'origine de l'action (notification tap, app, etc.).
  /// No-op si l'état courant est déjà [AsyncLoading] (guard BUG-003).
  Future<void> validate({
    ValidationSource source = ValidationSource.app,
  }) async {
    // Guard : ignore les taps multiples pendant un appel en cours.
    if (state.isLoading) {
      appLog.d(
        'OccurrenceValidationNotifier: ignored tap while loading '
        '(occurrenceId=$arg)',
      );
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref
          .read(validateOccurrenceUseCaseProvider)
          .call(occurrenceId: arg, source: source);
    });

    if (state.hasError) {
      appLog.e(
        'OccurrenceValidationNotifier: validation failed',
        error: state.error,
        stackTrace: state.stackTrace,
      );
    }
  }
}

/// Provider familial — un état par [occurrenceId].
///
/// Usage :
/// ```dart
/// // Dans un widget :
/// final validationState = ref.watch(
///   occurrenceValidationNotifierProvider(occurrence.id),
/// );
/// final isLoading = validationState.isLoading;
///
/// // Pour valider :
/// ref.read(
///   occurrenceValidationNotifierProvider(occurrence.id).notifier,
/// ).validate(source: ValidationSource.notificationAction);
/// ```
final occurrenceValidationNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<OccurrenceValidationNotifier, Occurrence?, String>(
      OccurrenceValidationNotifier.new,
    );
