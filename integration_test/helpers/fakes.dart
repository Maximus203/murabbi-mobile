import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/services/onboarding_flag_storage.dart';

/// Fake AuthRepository en mémoire.
///
/// Permet aux flows E2E de tester routing + UI + état Riverpod sans
/// dépendre de Supabase. Les méthodes sont configurables via constructeur
/// ou champs publics pour scripter des scénarios (signUp en attente de
/// vérif email, signIn ok, signOut, etc.).
class FakeAuthRepository implements AuthRepository {
  /// Compte préenregistré (utile pour Flow C — signIn direct). Si non null,
  /// `signIn` réussit avec ces credentials et renvoie cet utilisateur.
  final String? seededEmail;
  final String? seededPassword;

  /// Utilisateur courant exposé par [getCurrentUser] et le stream
  /// [authStateChanges]. Démarre généralement à `null` (déconnecté).
  User? _current;

  /// Compteur d'appels `getCurrentUser` — sert au Flow B pour simuler la
  /// confirmation d'email au Nᵉ poll. Si [emailConfirmsAfterNthGetCurrent]
  /// est fixé, à partir du Nᵉ appel l'utilisateur "verified" sera renvoyé.
  int _getCurrentCalls = 0;
  final int? emailConfirmsAfterNthGetCurrent;

  /// Utilisateur de signUp en attente de confirmation. Tant que la confirm
  /// n'est pas atteinte, [_current] reste null malgré `signUp` réussi
  /// (simule un session-less signup Supabase).
  User? _pendingSignUpUser;

  final StreamController<User?> _stateCtrl =
      StreamController<User?>.broadcast();

  FakeAuthRepository({
    this.seededEmail,
    this.seededPassword,
    User? initialUser,
    this.emailConfirmsAfterNthGetCurrent,
  }) : _current = initialUser;

  void _emit(User? user) {
    _current = user;
    _stateCtrl.add(user);
  }

  void dispose() => _stateCtrl.close();

  static User makeUser({
    String id = 'user-fake-1',
    String pseudo = 'Anonyme',
    String email = 'fake@murabbi.test',
    bool emailVerified = true,
  }) {
    return User(
      id: UserId(id),
      pseudo: NonEmptyString(pseudo),
      email: NonEmptyString(email),
      createdAt: DateTime.utc(2026, 1, 1),
      level: Level.aspirant,
      emailConfirmedAt: emailVerified ? DateTime.utc(2026, 1, 1) : null,
    );
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    if (seededEmail != null &&
        email == seededEmail &&
        password == seededPassword) {
      final user = makeUser(email: email, pseudo: 'Cherif');
      _emit(user);
      return user;
    }
    throw const AuthFailure.invalidCredentials();
  }

  @override
  Future<User> signUp({required String email, required String password}) async {
    final pending = makeUser(
      email: email,
      pseudo: 'Anonyme',
      emailVerified: false,
    );
    _pendingSignUpUser = pending;
    // Simule Supabase : signUp ouvre une session (le user est connu) mais
    // l'email n'est pas encore confirmé — l'app doit basculer sur AU-04.
    _emit(pending);
    return pending;
  }

  @override
  Future<User> signInWithGoogle() async {
    throw const AuthFailure.unknown(message: 'OAuth non simulé en E2E');
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    // No-op (mail envoyé côté Supabase en prod).
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    // No-op.
  }

  @override
  Future<void> signOut() async {
    _pendingSignUpUser = null;
    _emit(null);
  }

  @override
  Future<void> deleteAccount(UserId userId) async {
    _emit(null);
  }

  @override
  Future<User?> getCurrentUser() async {
    _getCurrentCalls += 1;
    final triggerAt = emailConfirmsAfterNthGetCurrent;
    if (triggerAt != null &&
        _pendingSignUpUser != null &&
        _getCurrentCalls >= triggerAt) {
      // Simule la confirmation d'email : le pending user devient
      // l'utilisateur courant avec emailConfirmedAt non null. On l'émet
      // aussi pour rafraîchir le stream.
      final pending = _pendingSignUpUser!;
      final confirmed = User(
        id: pending.id,
        pseudo: pending.pseudo,
        email: pending.email,
        createdAt: pending.createdAt,
        level: pending.level,
        currentStreak: pending.currentStreak,
        completionRate: pending.completionRate,
        emailConfirmedAt: DateTime.utc(2026, 5, 8),
      );
      _pendingSignUpUser = null;
      _emit(confirmed);
      return confirmed;
    }
    return _current;
  }

  @override
  Future<User?> refreshSession() async {
    // Symétrie avec getCurrentUser : permet aussi à AU-04 de "découvrir"
    // que l'email est désormais vérifié via le polling refreshSession.
    return getCurrentUser();
  }

  @override
  Stream<User?> get authStateChanges => _stateCtrl.stream;
}

/// Fake OnboardingFlagStorage en mémoire — démarrable "non onboardé"
/// (Flow A) ou "onboardé" (Flow B/C).
class FakeOnboardingFlagStorage implements OnboardingFlagStorage {
  bool _completed;

  FakeOnboardingFlagStorage({bool completed = false}) : _completed = completed;

  @override
  Future<bool> isCompleted() async => _completed;

  @override
  Future<void> markCompleted() async {
    _completed = true;
  }

  @override
  Future<void> reset() async {
    _completed = false;
  }
}

/// Construit la liste d'overrides Riverpod pour brancher un fake auth +
/// fake onboarding storage sur le `ProviderScope` racine.
List<Override> testOverrides({
  required FakeAuthRepository auth,
  required FakeOnboardingFlagStorage onboarding,
}) {
  return [
    authRepositoryProvider.overrideWithValue(auth),
    onboardingFlagStorageProvider.overrideWithValue(onboarding),
  ];
}
