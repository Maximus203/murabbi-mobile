import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/user_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';

/// ST-02 — Modification du profil utilisateur.
///
/// Seul le pseudo public est éditable (l'email est verrouillé côté UI).
/// La validation (longueur 1..30, caractères interdits) est portée par le
/// value object [Pseudonym] — toute saisie invalide lève `ArgumentError`
/// avant d'atteindre le repository.
class UpdateProfileUseCase {
  final UserRepository _repository;

  const UpdateProfileUseCase(this._repository);

  Future<User> call({required User currentUser, required String newPseudo}) {
    // `Pseudonym(...)` trim + valide ; lève ArgumentError si invalide.
    final pseudo = Pseudonym(newPseudo);
    return _repository.updateUser(currentUser.copyWith(pseudo: pseudo));
  }
}
