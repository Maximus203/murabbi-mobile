import 'package:equatable/equatable.dart';

/// Représente une heure du jour (HH:MM) en domaine pur.
///
/// Volontairement indépendant de `flutter.TimeOfDay` : la couche `domain`
/// ne peut pas dépendre de Flutter (cf. ADR-001 Clean Architecture).
class TimeOfDayValue extends Equatable {
  final int hour;
  final int minute;

  const TimeOfDayValue._(this.hour, this.minute);

  factory TimeOfDayValue(int hour, int minute) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be 0-23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be 0-59');
    }
    return TimeOfDayValue._(hour, minute);
  }

  /// Retourne true si `this` est strictement avant `other` dans la journée.
  /// N'autorise pas le wrap autour de minuit (cf. ADR-007).
  bool isBefore(TimeOfDayValue other) {
    if (hour != other.hour) return hour < other.hour;
    return minute < other.minute;
  }

  @override
  List<Object?> get props => [hour, minute];

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
