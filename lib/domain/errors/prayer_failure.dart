import 'package:equatable/equatable.dart';

/// Erreurs typées remontées par la couche `data` Salat (slice 3.B Phase 3).
///
/// Suit le pattern `AuthFailure` (cf. `lib/domain/errors/auth_failure.dart`) :
/// les exceptions natives Supabase (`PostgrestException`, `SocketException`,
/// etc.) sont traduites par le repository en l'une de ces failures, jamais
/// laissées remonter brutes vers la couche presentation.
sealed class PrayerFailure extends Equatable implements Exception {
  final String? message;

  const PrayerFailure._({this.message});

  /// Réseau indisponible / DNS échoué / timeout.
  const factory PrayerFailure.network({String? message}) = PrayerNetworkFailure;

  /// Erreur générique côté base (PostgrestException) — code/message original
  /// transporté pour debug.
  const factory PrayerFailure.database({String? message}) =
      PrayerDatabaseFailure;

  /// La row n'a pas la forme attendue (champ manquant, type incorrect,
  /// jour parsable). Indique un drift schéma.
  const factory PrayerFailure.malformedRow({String? message}) =
      PrayerMalformedRowFailure;

  /// La row contient une valeur inconnue côté domain (ex: `'skipped'` SQL
  /// legacy non mappé). Fail-fast volontaire.
  const factory PrayerFailure.unknownStatus({String? message}) =
      UnknownPrayerStatusFailure;

  /// Tout le reste — échec inattendu, le message décrit l'origine.
  const factory PrayerFailure.unknown({String? message}) = UnknownPrayerFailure;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

class PrayerNetworkFailure extends PrayerFailure {
  const PrayerNetworkFailure({super.message}) : super._();
}

class PrayerDatabaseFailure extends PrayerFailure {
  const PrayerDatabaseFailure({super.message}) : super._();
}

class PrayerMalformedRowFailure extends PrayerFailure {
  const PrayerMalformedRowFailure({super.message}) : super._();
}

class UnknownPrayerStatusFailure extends PrayerFailure {
  const UnknownPrayerStatusFailure({super.message}) : super._();
}

class UnknownPrayerFailure extends PrayerFailure {
  const UnknownPrayerFailure({super.message}) : super._();
}
