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

  const User({
    required this.id,
    required this.pseudo,
    required this.email,
    required this.createdAt,
    required this.level,
    this.currentStreak = 0,
    this.completionRate = 0,
    this.emailConfirmedAt,
  });

  /// `true` si l'utilisateur a confirmé son email côté Supabase.
  bool get isEmailVerified => emailConfirmedAt != null;

  /// Copie immuable avec champs surchargés — utilisé notamment par
  /// l'édition de profil ST-02 (mise à jour du pseudo).
  User copyWith({
    UserId? id,
    Pseudonym? pseudo,
    NonEmptyString? email,
    DateTime? createdAt,
    Level? level,
    int? currentStreak,
    double? completionRate,
    DateTime? emailConfirmedAt,
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
  ];
}
