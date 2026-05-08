import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';

/// Rafraîchit la session Supabase et retourne l'utilisateur à jour.
///
/// Utilisé par AU-04 (Au04EmailVerificationGate) pour détecter
/// automatiquement la confirmation d'email côté serveur sans nécessiter
/// d'action manuelle de l'utilisateur (Q2-C).
class RefreshSessionUseCase {
  final AuthRepository _repository;
  const RefreshSessionUseCase(this._repository);

  Future<User?> call() => _repository.refreshSession();
}
