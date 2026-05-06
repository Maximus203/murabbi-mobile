import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Mapper pur — convertit les maps remontées par la couche data en entité
/// `User`. Reçoit séparément :
///   - `authUser` : extrait de `Supabase.auth.currentUser` ({id, email, created_at})
///   - `profile`  : row de la table `profiles` ({display_name, total_points})
class UserMapper {
  const UserMapper._();

  static User fromMaps({
    required Map<String, dynamic> authUser,
    required Map<String, dynamic> profile,
  }) {
    final id = authUser['id'];
    final email = authUser['email'];
    final createdAtRaw = authUser['created_at'];
    final displayName = profile['display_name'];
    final totalPointsRaw = profile['total_points'];

    if (id is! String || id.isEmpty) {
      throw ArgumentError.value(id, 'authUser.id', 'must be a non-empty UUID');
    }
    if (email is! String) {
      throw ArgumentError.value(email, 'authUser.email', 'must be a String');
    }
    if (displayName is! String) {
      throw ArgumentError.value(
        displayName,
        'profile.display_name',
        'must be a String',
      );
    }
    if (totalPointsRaw is! int) {
      throw ArgumentError.value(
        totalPointsRaw,
        'profile.total_points',
        'must be an int',
      );
    }
    if (totalPointsRaw < 0) {
      throw ArgumentError.value(
        totalPointsRaw,
        'profile.total_points',
        'must be >= 0',
      );
    }

    final createdAt = createdAtRaw is DateTime
        ? createdAtRaw
        : DateTime.parse(createdAtRaw as String);

    return User(
      id: UserId(id),
      email: NonEmptyString(email),
      displayName: NonEmptyString(displayName),
      createdAt: createdAt,
      level: Level.fromPoints(totalPointsRaw),
    );
  }
}
