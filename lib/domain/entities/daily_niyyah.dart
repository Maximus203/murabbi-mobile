import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// The user's daily intention, persisted in Supabase (Q-03 A).
/// One entry per user per day — upsert on save.
class DailyNiyyah extends Equatable {
  final UserId userId;
  final DateTime date;
  final NonEmptyString text;

  const DailyNiyyah({
    required this.userId,
    required this.date,
    required this.text,
  });

  @override
  List<Object?> get props => [userId, date, text];
}
