import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/user_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';

/// ST-02 — Modification du profil utilisateur.
///
/// **DEPRECATED (issue #168 / admin#125)** : le pseudo est désormais
/// immuable côté serveur (la RPC `update_user_pseudo` lève
/// `PSEUDO_IMMUTABLE`). Plus aucun appelant côté `presentation` n'invoque
/// ce use case. Conservé temporairement pour préserver les tests existants
/// et permettre une suppression chirurgicale dans un PR de nettoyage
/// dédié.
@Deprecated(
  'Pseudo immuable depuis admin#125 (issue #168). À supprimer dans un PR '
  'de nettoyage dédié — plus aucun call-site présentation.',
)
class UpdateProfileUseCase {
  final UserRepository _repository;

  const UpdateProfileUseCase(this._repository);

  Future<User> call({required User currentUser, required String newPseudo}) {
    // `Pseudonym(...)` trim + valide ; lève ArgumentError si invalide.
    final pseudo = Pseudonym(newPseudo);
    return _repository.updateUser(currentUser.copyWith(pseudo: pseudo));
  }
}
