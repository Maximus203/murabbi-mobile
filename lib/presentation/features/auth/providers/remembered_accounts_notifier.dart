import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/prayer_settings_providers.dart'
    show sharedPreferencesProvider;
import 'package:murabbi_mobile/services/remembered_accounts_storage.dart';

/// Provider du service de persistance (réutilise [sharedPreferencesProvider]
/// déjà introduit en slice 3.C.2).
final rememberedAccountsStorageProvider =
    FutureProvider<RememberedAccountsStorage>((ref) async {
      final prefs = await ref.watch(sharedPreferencesProvider.future);
      return RememberedAccountsStorage(prefs);
    });

/// État réactif de la liste des emails mémorisés. Consommé par AU-01 (chips
/// au-dessus du champ email) — non bloquant : si le storage n'est pas prêt,
/// l'UI ne montre simplement aucune suggestion.
class RememberedAccountsNotifier extends AsyncNotifier<List<String>> {
  RememberedAccountsStorage? _storage;

  @override
  Future<List<String>> build() async {
    _storage = await ref.watch(rememberedAccountsStorageProvider.future);
    return _storage!.getAll();
  }

  /// Garantit que [build] s'est terminé avant d'utiliser `_storage` —
  /// protège contre les appels précoces (cf. test régression PR #41 :
  /// `AuthNotifier._rememberEmail` peut invoquer ce notifier avant que
  /// l'UI ait consommé le provider, donc avant que [build] ait initialisé
  /// `_storage`).
  Future<RememberedAccountsStorage> _ensureStorage() async {
    if (_storage != null) return _storage!;
    await future;
    return _storage!;
  }

  /// Mémorise (ou remonte en tête) l'email après un signIn / signUp réussi.
  Future<void> remember(String email) async {
    final storage = await _ensureStorage();
    await storage.remember(email);
    state = AsyncValue.data(storage.getAll());
  }

  /// Retire un email de la liste (interaction utilisateur "oublier ce
  /// compte").
  Future<void> forget(String email) async {
    final storage = await _ensureStorage();
    await storage.forget(email);
    state = AsyncValue.data(storage.getAll());
  }
}

final rememberedAccountsNotifierProvider =
    AsyncNotifierProvider<RememberedAccountsNotifier, List<String>>(
      RememberedAccountsNotifier.new,
    );
