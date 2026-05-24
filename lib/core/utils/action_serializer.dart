/// Sérialiseur léger d'actions asynchrones pour éviter les doublons
/// dus à un double-tap rapide ou un re-trigger UI concurrent.
///
/// Cf. issue #198 (M4) : les `AsyncNotifier` exposant une mutation
/// (`logHabit`, `markPrayer`, etc.) doivent encapsuler leurs appels
/// dans un `ActionSerializer` pour garantir qu'une seule mutation est
/// en vol à la fois.
///
/// Usage type dans un notifier :
/// ```dart
/// class FooNotifier extends AsyncNotifier<Foo> {
///   final _serializer = ActionSerializer();
///
///   Future<void> doSomething() async {
///     await _serializer.run(() async {
///       // mutation effective…
///     });
///   }
/// }
/// ```
///
/// Sémantique : si une action est déjà en cours, [run] retourne
/// immédiatement `null` (l'appelant peut choisir d'ignorer silencieusement
/// le second tap). Le verrou est toujours libéré, même si l'action lève
/// une exception (qui est ré-émise telle quelle).
class ActionSerializer {
  bool _inProgress = false;

  /// Indique si une action est actuellement en vol (exposé pour
  /// d'éventuels tests / diagnostics — l'API métier reste [run]).
  bool get isBusy => _inProgress;

  /// Exécute [action] si aucune autre action n'est en cours.
  ///
  /// Retourne le résultat de [action], ou `null` si une autre action
  /// était déjà en vol (l'appel est silencieusement ignoré).
  ///
  /// Toute exception levée par [action] est propagée à l'appelant
  /// après libération du verrou.
  Future<T?> run<T>(Future<T> Function() action) async {
    if (_inProgress) return null;
    _inProgress = true;
    try {
      return await action();
    } finally {
      _inProgress = false;
    }
  }
}
