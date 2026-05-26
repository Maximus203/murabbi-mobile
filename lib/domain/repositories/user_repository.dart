import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class UserRepository {
  Future<User?> getUser(UserId userId);
  Future<User> updateUser(User user);

  /// Q-26 Option A — met à jour le nom complet (`display_name`, colonne
  /// TEXT nullable dans `users`). Prend [currentUser] pour pouvoir retourner
  /// une entité complète sans re-joindre `auth.users`.
  Future<User> updateDisplayName(User currentUser, String displayName);
}
