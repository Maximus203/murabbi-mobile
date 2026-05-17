import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/user_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/update_profile_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Provider du use case d'édition de profil — surchargeable en test.
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(userRepositoryProvider));
});

/// Notifier de l'écran ST-02 — pilote l'enregistrement du pseudo.
///
/// `AsyncValue<void>` :
/// - `data(null)` → état de repos (aucune sauvegarde en cours)
/// - `loading()`  → enregistrement en cours
/// - `error(_)`   → dernier enregistrement échoué (pseudo invalide ou réseau)
class EditProfileNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Enregistre le nouveau pseudo. En cas de succès, rafraîchit
  /// `authNotifierProvider` pour propager le profil mis à jour à toute l'app.
  Future<bool> save(String newPseudo) async {
    final currentUser = await ref.read(authNotifierProvider.future);
    if (currentUser == null) return false;

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard<User>(() {
      return ref
          .read(updateProfileUseCaseProvider)
          .call(currentUser: currentUser, newPseudo: newPseudo);
    });
    state = result.hasError
        ? AsyncValue.error(result.error!, result.stackTrace!)
        : const AsyncValue.data(null);
    if (!result.hasError) {
      ref.invalidate(authNotifierProvider);
    }
    return !result.hasError;
  }
}

final editProfileNotifierProvider =
    AsyncNotifierProvider<EditProfileNotifier, void>(EditProfileNotifier.new);
