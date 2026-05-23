import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Entité utilisateur — reflète la table `users` côté admin (Q-18).
class User extends Equatable {
  final UserId id;
  final Pseudonym pseudo;
  final NonEmptyString email;
  final DateTime createdAt;
  final Level level;
  final int currentStreak;
  final double completionRate;

  /// Timestamp de confirmation d'email côté `auth.users.email_confirmed_at`
  /// (Supabase). `null` = pas encore vérifié — bloque l'utilisateur sur
  /// AU-04. Utilisé par le polling `RefreshSessionUseCase` (Q2-C) pour
  /// auto-quitter le sas verify-email.
  final DateTime? emailConfirmedAt;

  /// Pseudo public canonique au format `pseudo#XXXX` (XXXX = suffixe CSPRNG
  /// 1000..9999) — colonne `users.pseudo_full` GENERATED ALWAYS AS STORED
  /// côté admin (migration `murabbi-admin#125`, issue mobile #168).
  ///
  /// Nullable tant que la migration admin n'est pas déployée pour tous les
  /// comptes existants. Toujours non-null pour les comptes créés après
  /// déploiement. Utiliser [displayPseudo] pour lire la valeur à afficher
  /// (avec fallback automatique sur [pseudo]).
  final String? pseudoFull;

  const User({
    required this.id,
    required this.pseudo,
    required this.email,
    required this.createdAt,
    required this.level,
    this.currentStreak = 0,
    this.completionRate = 0,
    this.emailConfirmedAt,
    this.pseudoFull,
  });

  /// `true` si l'utilisateur a confirmé son email côté Supabase.
  bool get isEmailVerified => emailConfirmedAt != null;

  /// Pseudo à afficher dans toute l'UI (issue #168). Retourne [pseudoFull]
  /// s'il est disponible (`pseudo#XXXX`), sinon retombe sur la valeur brute
  /// de [pseudo] — utile pour les comptes existants avant migration admin.
  String get displayPseudo => pseudoFull ?? pseudo.value;

  /// Copie immuable avec champs surchargés. Note : depuis l'issue #168 et
  /// la migration admin#125, `pseudo` est immuable côté serveur — le seul
  /// usage légitime côté mobile reste la lecture (mapper, tests).
  User copyWith({
    UserId? id,
    Pseudonym? pseudo,
    NonEmptyString? email,
    DateTime? createdAt,
    Level? level,
    int? currentStreak,
    double? completionRate,
    DateTime? emailConfirmedAt,
    String? pseudoFull,
  }) {
    return User(
      id: id ?? this.id,
      pseudo: pseudo ?? this.pseudo,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      completionRate: completionRate ?? this.completionRate,
      emailConfirmedAt: emailConfirmedAt ?? this.emailConfirmedAt,
      pseudoFull: pseudoFull ?? this.pseudoFull,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pseudo,
    email,
    createdAt,
    level,
    currentStreak,
    completionRate,
    emailConfirmedAt,
    pseudoFull,
  ];
}
