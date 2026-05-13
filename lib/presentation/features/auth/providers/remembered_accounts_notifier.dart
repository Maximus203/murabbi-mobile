import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/prayer_times_provider.dart'
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
  late RememberedAccountsStorage _storage;

  @override
  Future<List<String>> build() async {
    _storage = await ref.watch(rememberedAccountsStorageProvider.future);
    return _storage.getAll();
  }

  /// Mémorise (ou remonte en tête) l'email après un signIn / signUp réussi.
  Future<void> remember(String email) async {
    await _storage.remember(email);
    state = AsyncValue.data(_storage.getAll());
  }

  /// Retire un email de la liste (interaction utilisateur "oublier ce
  /// compte").
  Future<void> forget(String email) async {
    await _storage.forget(email);
    state = AsyncValue.data(_storage.getAll());
  }
}

final rememberedAccountsNotifierProvider =
    AsyncNotifierProvider<RememberedAccountsNotifier, List<String>>(
      RememberedAccountsNotifier.new,
    );
