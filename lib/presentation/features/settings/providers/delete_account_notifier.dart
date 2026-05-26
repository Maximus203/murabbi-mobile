import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/delete_account_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Provider du use case de suppression de compte — surchargeable en test.
final deleteAccountUseCaseProvider = Provider<DeleteAccountUseCase>((ref) {
  return DeleteAccountUseCase(ref.watch(authRepositoryProvider));
});

/// Notifier de l'écran ST-03 — pilote la suppression de compte.
///
/// `AsyncValue<void>` :
/// - `data(null)` → repos
/// - `loading()`  → suppression en cours
/// - `error(_)`   → suppression échouée
///
/// Règle C-1 (issue #7) : la suppression doit être un DELETE cascade réel
/// en base. Le `DeleteAccountUseCase` est le point d'orchestration ; la
/// suppression cascade effective (habits, logs, collections, user_data)
/// dépend du backend Supabase — voir TODO PO dans `delete_account_use_case`.
class DeleteAccountNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Supprime le compte de l'utilisateur connecté puis le déconnecte.
  /// Renvoie `true` en cas de succès.
  Future<bool> deleteCurrentAccount() async {
    // `.future` garantit que l'auth state est résolu avant lecture (le
    // provider peut ne pas avoir encore été watché par l'UI).
    final user = await ref.read(authNotifierProvider.future);
    if (user == null) return false;

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() {
      return ref.read(deleteAccountUseCaseProvider).call(user.id);
    });
    state = result;
    return !result.hasError;
  }
}

final deleteAccountNotifierProvider =
    AsyncNotifierProvider<DeleteAccountNotifier, void>(
      DeleteAccountNotifier.new,
    );
