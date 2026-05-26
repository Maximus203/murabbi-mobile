import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Mapper pur — convertit les maps remontées par la couche data en entité
/// `User`. Reçoit séparément :
///   - `authUser` : extrait de `Supabase.auth.currentUser`
///                  ({id, email, created_at})
///   - `profile`  : row de la table `users` Q-18 :
///                  {pseudo, email, level, current_streak, completion_rate,
///                   deletion_requested_at}
///
/// Le score cumulé n'est PAS sur `users` — il vit sur
/// `user_scores.total_score` et sera lu par un futur `UserScoreRepository`
/// (slice scoring). Ce mapper ne le projette donc pas.
///
/// Lève [AuthFailure.accountDeleted] si `profile.deletion_requested_at` n'est
/// pas null (cf. ADR-011 — soft-delete cooling period 30j).
class UserMapper {
  const UserMapper._();

  static User fromMaps({
    required Map<String, dynamic> authUser,
    required Map<String, dynamic> profile,
  }) {
    final id = authUser['id'];
    final emailAuth = authUser['email'];
    final createdAtRaw = authUser['created_at'];
    final emailConfirmedAtRaw = authUser['email_confirmed_at'];

    final pseudo = profile['pseudo'];
    final pseudoFullRaw = profile['pseudo_full'];
    final displayNameRaw = profile['display_name'];
    final levelRaw = profile['level'];
    final currentStreakRaw = profile['current_streak'];
    final completionRateRaw = profile['completion_rate'];
    final deletionRequestedAt = profile['deletion_requested_at'];

    if (id is! String || id.isEmpty) {
      throw ArgumentError.value(id, 'authUser.id', 'must be a non-empty UUID');
    }
    if (emailAuth is! String) {
      throw ArgumentError.value(
        emailAuth,
        'authUser.email',
        'must be a String',
      );
    }
    if (pseudo is! String) {
      throw ArgumentError.value(pseudo, 'profile.pseudo', 'must be a String');
    }
    if (levelRaw is! String) {
      throw ArgumentError.value(levelRaw, 'profile.level', 'must be a String');
    }
    if (currentStreakRaw is! int || currentStreakRaw < 0) {
      throw ArgumentError.value(
        currentStreakRaw,
        'profile.current_streak',
        'must be a non-negative int',
      );
    }
    if (completionRateRaw is! num || completionRateRaw < 0) {
      throw ArgumentError.value(
        completionRateRaw,
        'profile.completion_rate',
        'must be a non-negative number',
      );
    }

    if (deletionRequestedAt != null) {
      throw const AuthFailure.accountDeleted(
        message: 'Account is in soft-delete cooling period (ADR-011).',
      );
    }

    final createdAt = createdAtRaw is DateTime
        ? createdAtRaw
        : DateTime.parse(createdAtRaw as String);

    DateTime? emailConfirmedAt;
    if (emailConfirmedAtRaw is DateTime) {
      emailConfirmedAt = emailConfirmedAtRaw;
    } else if (emailConfirmedAtRaw is String &&
        emailConfirmedAtRaw.isNotEmpty) {
      emailConfirmedAt = DateTime.parse(emailConfirmedAtRaw);
    }

    // Issue #168 / admin#125 — `pseudo_full` est une colonne GENERATED
    // STORED côté Postgres ; en lecture on la projette telle quelle. Si
    // la colonne est absente (rows pré-migration) ou null, on retombe sur
    // null et `User.displayPseudo` reprend `pseudo` brut.
    String? pseudoFull;
    if (pseudoFullRaw is String && pseudoFullRaw.isNotEmpty) {
      pseudoFull = pseudoFullRaw;
    }

    // Q-26 Option A — `display_name` (colonne TEXT nullable, migration à
    // appliquer côté murabbi-admin). Absente ou vide → null.
    String? displayName;
    if (displayNameRaw is String && displayNameRaw.isNotEmpty) {
      displayName = displayNameRaw;
    }

    return User(
      id: UserId(id),
      pseudo: Pseudonym(pseudo),
      email: NonEmptyString(emailAuth),
      createdAt: createdAt,
      level: Level.fromString(levelRaw),
      currentStreak: currentStreakRaw,
      completionRate: completionRateRaw.toDouble(),
      emailConfirmedAt: emailConfirmedAt,
      pseudoFull: pseudoFull,
      displayName: displayName,
    );
  }
}
