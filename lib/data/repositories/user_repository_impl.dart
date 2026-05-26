import 'package:murabbi_mobile/data/datasources/user_data_source.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/user_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Implémentation Supabase du [UserRepository] — délègue à un
/// [UserDataSource]. Suit le pattern `ScoreRepositoryImpl` (#6).
///
/// Périmètre ST-02 : seule l'écriture du pseudo est couverte. La lecture
/// du profil reste portée par `AuthRepository.getCurrentUser` (la SoT de
/// l'identité jointe `auth.users` + `public.users`), donc [getUser] renvoie
/// `null` ici — il n'est pas utilisé par la couche presentation.
class UserRepositoryImpl implements UserRepository {
  final UserDataSource _ds;

  const UserRepositoryImpl(this._ds);

  @override
  Future<User?> getUser(UserId userId) async => null;

  @override
  Future<User> updateUser(User user) async {
    final row = await _ds.updatePseudo(
      userId: user.id.value,
      pseudo: user.pseudo.value,
    );
    // Le datasource confirme l'écriture en relisant la row `users`. On
    // reprojette le pseudo persisté sur l'entité fournie (l'identité
    // auth — email, createdAt — n'est pas touchée par ST-02).
    final persistedPseudo = row['pseudo'];
    if (persistedPseudo is String && persistedPseudo.isNotEmpty) {
      return user.copyWith(pseudo: Pseudonym(persistedPseudo));
    }
    return user;
  }
}
