import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';

/// Dérivation typée de l'utilisateur courant — `null` si la session n'est pas
/// (encore) hydratée, le user sinon.
///
/// Ce provider sert de point d'override unique pour les tests des features
/// authentifiées (Salat slice 3.C.3, Dashboard 3.A, Habitudes 3.D…). Plutôt
/// que d'override `authNotifierProvider` (`AsyncNotifierProvider` avec
/// dépendances internes) chaque feature override ce provider trivial avec
/// `overrideWithValue(testUser)`.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});
