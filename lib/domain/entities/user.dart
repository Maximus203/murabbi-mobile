import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class User extends Equatable {
  final UserId id;
  final NonEmptyString displayName;
  final NonEmptyString email;
  final DateTime createdAt;
  final Level level;

  const User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.createdAt,
    required this.level,
  });

  @override
  List<Object?> get props => [id, displayName, email, createdAt, level];
}
