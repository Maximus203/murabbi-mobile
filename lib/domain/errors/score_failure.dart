import 'package:equatable/equatable.dart';

/// Erreurs typées remontées par la couche `data` Score / Leaderboard.
///
/// Suit le pattern [PrayerFailure] : les exceptions natives Supabase sont
/// traduites par [ScoreRepositoryImpl] en l'une de ces failures, jamais
/// laissées remonter brutes vers la couche presentation.
sealed class ScoreFailure extends Equatable implements Exception {
  final String? message;

  const ScoreFailure._({this.message});

  /// Réseau indisponible / timeout.
  const factory ScoreFailure.network({String? message}) = ScoreNetworkFailure;

  /// Erreur côté base (PostgrestException).
  const factory ScoreFailure.database({String? message}) = ScoreDatabaseFailure;

  /// Score introuvable pour l'utilisateur (row absente).
  const factory ScoreFailure.notFound({String? message}) = ScoreNotFoundFailure;

  /// Tout le reste.
  const factory ScoreFailure.unknown({String? message}) = ScoreUnknownFailure;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

class ScoreNetworkFailure extends ScoreFailure {
  const ScoreNetworkFailure({super.message}) : super._();
}

class ScoreDatabaseFailure extends ScoreFailure {
  const ScoreDatabaseFailure({super.message}) : super._();
}

class ScoreNotFoundFailure extends ScoreFailure {
  const ScoreNotFoundFailure({super.message}) : super._();
}

class ScoreUnknownFailure extends ScoreFailure {
  const ScoreUnknownFailure({super.message}) : super._();
}
