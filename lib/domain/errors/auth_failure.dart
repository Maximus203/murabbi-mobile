import 'package:equatable/equatable.dart';

/// Erreurs typées remontées par la couche `data` quand une opération auth
/// échoue. Permet à l'UI (`presentation/`) de switcher exhaustivement sur les
/// causes sans interpréter les exceptions natives Supabase.
sealed class AuthFailure extends Equatable implements Exception {
  final String? message;

  const AuthFailure._({this.message});

  const factory AuthFailure.invalidCredentials({String? message}) =
      InvalidCredentialsFailure;

  const factory AuthFailure.emailAlreadyInUse({String? message}) =
      EmailAlreadyInUseFailure;

  const factory AuthFailure.weakPassword({String? message}) =
      WeakPasswordFailure;

  const factory AuthFailure.network({String? message}) = NetworkFailure;

  /// Compte en cooling period (cf. ADR-011) : l'utilisateur a demandé la
  /// suppression et `users.deletion_requested_at IS NOT NULL`. Connexion
  /// refusée jusqu'au hard-delete batch admin (J+30).
  const factory AuthFailure.accountDeleted({String? message}) =
      AccountDeletedFailure;

  const factory AuthFailure.unknown({String? message}) = UnknownAuthFailure;

  @override
  List<Object?> get props => [runtimeType, message];

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure({super.message}) : super._();
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure({super.message}) : super._();
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure({super.message}) : super._();
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure({super.message}) : super._();
}

class AccountDeletedFailure extends AuthFailure {
  const AccountDeletedFailure({super.message}) : super._();
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure({super.message}) : super._();
}
