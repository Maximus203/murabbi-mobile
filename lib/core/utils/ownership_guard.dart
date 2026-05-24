/// Mixin de défense en profondeur pour les repositories qui acceptent un
/// `userId` côté contrat.
///
/// Cf. issue #202 (M3) : la RLS Supabase reste la protection réelle, mais
/// un bug client qui passerait un `userId` différent de celui de la session
/// courante remontait une `PostgrestException` générique sans message
/// métier. Le mixin permet aux repositories d'échouer avec une
/// `Failure.unauthorized()` typée **avant** tout appel réseau.
///
/// Usage type :
/// ```dart
/// class HabitRepositoryImpl with OwnershipGuard implements HabitRepository {
///   @override
///   Future<void> logHabit(UserId userId, ...) async {
///     final currentId = await _currentUserResolver.currentUserId();
///     assertOwnership(
///       requestedId: userId.value,
///       currentId: currentId,
///       failureIfMismatch: const HabitFailure.unauthorized(),
///     );
///     // ... suite normale
///   }
/// }
/// ```
mixin OwnershipGuard {
  /// Vérifie que [requestedId] correspond à [currentId]. Lève
  /// [failureIfMismatch] sinon — la valeur passée doit être une `Failure`
  /// typée de la feature concernée (ex. `HabitFailure.unauthorized()`).
  ///
  /// La signature accepte `currentId` nullable pour gérer le cas
  /// "session expirée" : si `currentId == null`, l'ownership est
  /// considéré comme mismatché.
  void assertOwnership({
    required String requestedId,
    required String? currentId,
    required Object failureIfMismatch,
  }) {
    if (currentId == null || requestedId != currentId) {
      throw failureIfMismatch;
    }
  }
}
