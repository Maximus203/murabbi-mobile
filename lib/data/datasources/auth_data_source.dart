/// Interface fine au-dessus de Supabase auth + table `users` (Q-18).
///
/// Toutes les méthodes retournent des `Map<String, dynamic>` bruts ou null —
/// le mapping vers les entités domaine est délégué à `UserMapper` côté
/// repository (cf. ADR-004 datasource pattern).
///
/// Les exceptions remontées par les implémentations (Supabase notamment) sont
/// traduites en `AuthFailure` par le repository, jamais ici.
abstract interface class AuthDataSource {
  /// Renvoie `{authUser, profile}` après un signIn email/password.
  /// `profile` est la row `users` (avec `deletion_requested_at` éventuel —
  /// le repository décide de bloquer ou non, cf. ADR-011).
  Future<({Map<String, dynamic> authUser, Map<String, dynamic> profile})>
  signInWithPassword({required String email, required String password});

  /// Crée un compte (auth + row `users`), renvoie `{authUser, profile}`.
  ///
  /// [displayName] est le nom choisi par l'utilisateur à l'inscription
  /// (#131) — transmis dans les metadata Supabase (`data: {display_name}`)
  /// pour que le trigger `on_auth_user_created` l'utilise comme `pseudo`
  /// au lieu du placeholder auto-généré.
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

  /// Resend Supabase signup confirmation email — `auth.resend(type: signup)`.
  Future<void> resendVerificationEmail({required String email});

  Future<void> signOut();

  /// Soft-delete (cf. ADR-011) : pose `users.deletion_requested_at = now()`
  /// puis signOut. Le hard-delete cascade RGPD est exécuté par un job batch
  /// admin scheduled (J+30).
  Future<void> deleteAccount(String userId);

  /// Snapshot synchrone : `null` si non authentifié, sinon `{authUser, profile}`.
  Future<({Map<String, dynamic> authUser, Map<String, dynamic> profile})?>
  getCurrentUser();

  /// Force un refresh de la session côté Supabase (reload du JWT et de
  /// `auth.users`). Renvoie `null` si plus de session.
  Future<({Map<String, dynamic> authUser, Map<String, dynamic> profile})?>
  refreshSession();

  /// Stream qui émet `null` à la déconnexion et le couple `{authUser, profile}`
  /// à la connexion / refresh.
  Stream<({Map<String, dynamic> authUser, Map<String, dynamic> profile})?>
  get authStateChanges;
}
