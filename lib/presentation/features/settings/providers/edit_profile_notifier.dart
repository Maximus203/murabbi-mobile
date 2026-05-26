import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/user_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/update_display_name_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/update_profile_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Provider du use case d'édition de profil — surchargeable en test.
///
/// **DEPRECATED (issue #168)** : plus utilisé par la presentation depuis
/// le passage en lecture seule de ST-02. Conservé pour les tests existants.
// ignore: deprecated_member_use_from_same_package
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  // ignore: deprecated_member_use_from_same_package
  return UpdateProfileUseCase(ref.watch(userRepositoryProvider));
});

/// Q-26 Option A — provider du use case de mise à jour du nom complet.
/// Surchargeable en test.
final updateDisplayNameUseCaseProvider =
    Provider<UpdateDisplayNameUseCase>((ref) {
  return UpdateDisplayNameUseCase(ref.watch(userRepositoryProvider));
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

  /// Q-26 Option A — enregistre le nom complet (`display_name`).
  /// En cas de succès, rafraîchit `authNotifierProvider`.
  Future<bool> saveDisplayName(String displayName) async {
    final currentUser = await ref.read(authNotifierProvider.future);
    if (currentUser == null) return false;

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard<User>(() {
      return ref
          .read(updateDisplayNameUseCaseProvider)
          .call(currentUser: currentUser, displayName: displayName);
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
