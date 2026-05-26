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

  /// Nom complet choisi par l'utilisateur (Q-26 Option A).
  ///
  /// Colonne `users.display_name TEXT` — nullable tant que la migration admin
  /// correspondante n'est pas déployée (`ALTER TABLE users ADD COLUMN
  /// display_name TEXT;` — murabbi-admin issue à créer). Distinct du
  /// [pseudo] (classement) et de [pseudoFull] : visible uniquement dans
  /// ST-02, jamais affiché dans le leaderboard.
  ///
  /// [displayPseudo] retourne cette valeur en priorité si non nulle et non vide.
  final String? displayName;

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
    this.displayName,
  });

  /// `true` si l'utilisateur a confirmé son email côté Supabase.
  bool get isEmailVerified => emailConfirmedAt != null;

  /// Valeur à afficher dans toute l'UI — ordre de priorité (Q-26) :
  /// 1. [displayName] si non null et non vide/blanc (nom complet saisi ST-02).
  /// 2. [pseudoFull] si disponible (`pseudo#XXXX`, migration admin#125).
  /// 3. [pseudo] brut — fallback ultime (comptes pré-migration).
  String get displayPseudo {
    final dn = displayName;
    if (dn != null && dn.trim().isNotEmpty) return dn;
    return pseudoFull ?? pseudo.value;
  }

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
    String? displayName,
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
      displayName: displayName ?? this.displayName,
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
    displayName,
  ];
}
