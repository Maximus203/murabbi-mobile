import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';

/// État global d'authentification de l'utilisateur courant.
///
/// `AsyncValue<User?>` :
/// - `data(null)` → non authentifié
/// - `data(User)` → authentifié
/// - `loading()`  → opération en cours (signIn / signUp / etc.)
/// - `error(AuthFailure)` → échec dernier appel (sealed, switch exhaustif UI)
///
/// La méthode `sendPasswordReset` ne touche pas au state principal et renvoie
/// un `bool` (anti-enumeration OWASP, cf. Q-7) — l'UI affiche le succès
/// générique quel que soit le résultat.
class AuthNotifier extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  StreamSubscription<User?>? _sub;

  @override
  Future<User?> build() async {
    final repo = _repo;
    ref.onDispose(() => _sub?.cancel());
    _sub = repo.authStateChanges.listen(
      (user) => state = AsyncValue.data(user),
      onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
    );
    return repo.getCurrentUser();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signIn(email: email, password: password),
    );
  }

  /// Q-18 : pas de pseudo à l'inscription (auto-généré côté data layer).
  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signUp(email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.signInWithGoogle());
  }

  /// Renvoie `true` si l'envoi a réussi côté Supabase, `false` sinon.
  /// L'UI affiche TOUJOURS le succès générique (Q-7 OWASP anti-enumeration).
  /// Le `bool` est utilisé uniquement pour télémétrie / retry futur.
  Future<bool> sendPasswordReset({required String email}) async {
    try {
      await _repo.sendPasswordResetEmail(email: email);
      return true;
    } on AuthFailure {
      return false;
    }
  }

  /// Renvoie l'email de confirmation d'inscription (Supabase
  /// `auth.resend(type: signup)`). Pattern identique à [sendPasswordReset] :
  /// ne touche pas au state principal, retourne un `bool` (utile pour
  /// distinguer rate-limit / network côté UI si besoin).
  Future<bool> resendVerificationEmail({required String email}) async {
    try {
      await _repo.resendVerificationEmail(email: email);
      return true;
    } on AuthFailure {
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.signOut();
      return null;
    });
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
