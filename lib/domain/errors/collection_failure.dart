import 'package:equatable/equatable.dart';

/// Erreurs typées remontées par la couche `data` Collections.
///
/// Suit le pattern [PrayerFailure] / [ScoreFailure].
sealed class CollectionFailure extends Equatable implements Exception {
  final String? message;

  const CollectionFailure._({this.message});

  const factory CollectionFailure.network({String? message}) =
      CollectionNetworkFailure;
  const factory CollectionFailure.database({String? message}) =
      CollectionDatabaseFailure;
  const factory CollectionFailure.notFound({String? message}) =
      CollectionNotFoundFailure;
  const factory CollectionFailure.unknown({String? message}) =
      CollectionUnknownFailure;

  /// Défense en profondeur : `userId` demandé ≠ utilisateur authentifié
  /// (cf. issue #202 / M3). Levée avant tout appel réseau — la RLS
  /// Supabase reste la protection finale.
  const factory CollectionFailure.unauthorized({String? message}) =
      CollectionUnauthorizedFailure;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

class CollectionNetworkFailure extends CollectionFailure {
  const CollectionNetworkFailure({super.message}) : super._();
}

class CollectionDatabaseFailure extends CollectionFailure {
  const CollectionDatabaseFailure({super.message}) : super._();
}

class CollectionNotFoundFailure extends CollectionFailure {
  const CollectionNotFoundFailure({super.message}) : super._();
}

class CollectionUnknownFailure extends CollectionFailure {
  const CollectionUnknownFailure({super.message}) : super._();
}

class CollectionUnauthorizedFailure extends CollectionFailure {
  const CollectionUnauthorizedFailure({super.message}) : super._();
}
