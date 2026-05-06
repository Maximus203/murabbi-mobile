/// Interface fine au-dessus de Supabase auth + table `profiles`.
///
/// Toutes les méthodes retournent des `Map<String, dynamic>` bruts ou null —
/// le mapping vers les entités domaine est délégué à `UserMapper` côté
/// repository (cf. ADR-004 datasource pattern).
///
/// Les exceptions remontées par les implémentations (Supabase notamment) sont
/// traduites en `AuthFailure` par le repository, jamais ici.
abstract interface class AuthDataSource {
  /// Renvoie `{authUser, profile}` après un signIn email/password.
  Future<({Map<String, dynamic> authUser, Map<String, dynamic> profile})>
  signInWithPassword({required String email, required String password});

  /// Crée un compte + profile, renvoie `{authUser, profile}`.
  Future<({Map<String, dynamic> authUser, Map<String, dynamic> profile})>
  signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// OAuth Google. Bloque jusqu'à la fin du redirect, puis renvoie
  /// `{authUser, profile}`.
  Future<({Map<String, dynamic> authUser, Map<String, dynamic> profile})>
  signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  /// Suppression du compte. Délègue à un RPC Supabase `delete_account` (Edge
  /// function) car le SDK client n'expose pas `auth.admin.deleteUser`.
  Future<void> deleteAccount(String userId);

  /// Snapshot synchrone : `null` si non authentifié, sinon `{authUser, profile}`.
  Future<({Map<String, dynamic> authUser, Map<String, dynamic> profile})?>
  getCurrentUser();

  /// Stream qui émet `null` à la déconnexion et le couple `{authUser, profile}`
  /// à la connexion / refresh.
  Stream<({Map<String, dynamic> authUser, Map<String, dynamic> profile})?>
  get authStateChanges;
}
