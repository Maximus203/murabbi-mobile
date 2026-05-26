import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

/// ST-03 — Suppression de compte (RGPD).
///
/// Point d'orchestration unique de la suppression. Délègue à
/// [AuthRepository.deleteAccount], qui déclenche la suppression côté backend
/// puis le `signOut`.
///
/// **Règle C-1 (issue #7) — TODO PO / backend** : la Phase 6 exige un DELETE
/// cascade RÉEL (users, habits, habit_logs, collections, user_data — aucun
/// orphelin), pas un soft-delete. L'implémentation Supabase actuelle
/// (`SupabaseAuthDataSource.deleteAccount`) suit encore ADR-011 (soft-delete
/// `deletion_requested_at` + job batch J+30). La bascule en hard-delete
/// cascade nécessite, côté `murabbi-admin` :
///   1. une fonction RPC `delete_account_cascade(uid)` SECURITY DEFINER qui
///      supprime en cascade toutes les tables enfants puis `auth.users` ;
///   2. la mise à jour de `SupabaseAuthDataSource.deleteAccount` pour
///      appeler cette RPC au lieu de l'UPDATE soft-delete.
/// Ce use case reste le seam stable : l'UI (ST-03) n'a pas à changer quand
/// le backend bascule. Conflit ADR-011 vs C-1 à arbitrer par le PO.
class DeleteAccountUseCase {
  final AuthRepository _repository;
  const DeleteAccountUseCase(this._repository);

  Future<void> call(UserId userId) => _repository.deleteAccount(userId);
}
