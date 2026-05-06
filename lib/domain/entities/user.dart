import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// Entité utilisateur — reflète la table `users` côté admin (Q-18).
class User extends Equatable {
  final UserId id;
  final NonEmptyString pseudo;
  final NonEmptyString email;
  final DateTime createdAt;
  final Level level;
  final int currentStreak;
  final double completionRate;

  const User({
    required this.id,
    required this.pseudo,
    required this.email,
    required this.createdAt,
    required this.level,
    this.currentStreak = 0,
    this.completionRate = 0,
  });

  @override
  List<Object?> get props => [
    id,
    pseudo,
    email,
    createdAt,
    level,
    currentStreak,
    completionRate,
  ];
}
