import 'package:equatable/equatable.dart';

/// Erreurs typées remontées par la couche `data` Habitudes (#164).
///
/// Suit le pattern [PrayerFailure] : les exceptions natives Supabase
/// (`PostgrestException`, etc.) sont traduites par le repository ou le
/// datasource en l'une de ces failures, jamais laissées remonter brutes.
sealed class HabitFailure extends Equatable implements Exception {
  final String? message;

  const HabitFailure._({this.message});

  /// Date future interdite — la RPC `toggle_habit_log` retourne
  /// `FUTURE_LOG_NOT_ALLOWED`.
  const factory HabitFailure.futureLogNotAllowed({String? message}) =
      HabitFutureLogNotAllowedFailure;

  /// Rétrodatation trop ancienne (> 8 jours) — la RPC retourne
  /// `BACKDATE_TOO_OLD`.
  const factory HabitFailure.backdateTooOld({String? message}) =
      HabitBackdateTooOldFailure;

  /// Erreur générique côté base (PostgrestException) — code/message original
  /// transporté pour debug.
  const factory HabitFailure.database({String? message}) = HabitDatabaseFailure;

  /// Réseau indisponible / DNS échoué / timeout.
  const factory HabitFailure.network({String? message}) = HabitNetworkFailure;

  /// Défense en profondeur : `userId` demandé ≠ utilisateur authentifié
  /// (cf. issue #202 / M3). Levée avant tout appel réseau — la RLS
  /// Supabase reste la protection finale.
  const factory HabitFailure.unauthorized({String? message}) =
      HabitUnauthorizedFailure;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

class HabitFutureLogNotAllowedFailure extends HabitFailure {
  const HabitFutureLogNotAllowedFailure({super.message}) : super._();
}

class HabitBackdateTooOldFailure extends HabitFailure {
  const HabitBackdateTooOldFailure({super.message}) : super._();
}

class HabitDatabaseFailure extends HabitFailure {
  const HabitDatabaseFailure({super.message}) : super._();
}

class HabitNetworkFailure extends HabitFailure {
  const HabitNetworkFailure({super.message}) : super._();
}

class HabitUnauthorizedFailure extends HabitFailure {
  const HabitUnauthorizedFailure({super.message}) : super._();
}
