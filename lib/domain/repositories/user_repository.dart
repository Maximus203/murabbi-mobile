import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class UserRepository {
  Future<User?> getUser(UserId userId);
  Future<User> updateUser(User user);
}
