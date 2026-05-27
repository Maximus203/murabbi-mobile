import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/user_repository.dart';

/// Q-26 Option A — Mise à jour du nom complet (`display_name`) utilisateur.
///
/// Nécessite la migration côté murabbi-admin :
///   `ALTER TABLE users ADD COLUMN display_name TEXT;`
///
/// Distinct de [UpdateProfileUseCase] (pseudo immuable depuis #168). Le
/// `displayName` est un alias personnel visible uniquement dans ST-02 — il
/// n'est pas affiché dans le leaderboard (`pseudo_full` reste la SoT publique).
class UpdateDisplayNameUseCase {
  final UserRepository _repository;

  const UpdateDisplayNameUseCase(this._repository);

  /// Met à jour le nom complet après trim. Renvoie l'entité [User] mise à
  /// jour depuis le repository (confirme la persistance).
  Future<User> call({
    required User currentUser,
    required String displayName,
  }) {
    return _repository.updateDisplayName(currentUser, displayName.trim());
  }
}
