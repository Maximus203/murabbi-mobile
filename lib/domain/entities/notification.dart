import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';

enum NotificationType { prayer, habit }

class AppNotification extends Equatable {
  final NonEmptyString id;
  final NonEmptyString title;
  final NonEmptyString body;
  final DateTime scheduledAt;
  final NotificationType type;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.type,
  });

  @override
  List<Object?> get props => [id, title, body, scheduledAt, type];
}
