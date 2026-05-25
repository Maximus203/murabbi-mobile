import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_screen.dart';

/// Wrapper "gate" — branche [Au04EmailVerificationScreen] sur le routeur :
/// - lit l'email depuis `authNotifierProvider` (utilisateur fraîchement
///   signé up, session active mais email pas encore confirmé) ;
/// - démarre un `Timer.periodic` de 5s qui appelle
///   `AuthRepository.refreshSession()` (Q2-C). À chaque tick, si Supabase
///   a flippé `email_confirmed_at`, l'utilisateur retourné a
///   `isEmailVerified == true` et on déclenche `onContinue` automatiquement
///   sans que l'utilisateur ait à appuyer sur le bouton manuel ;
/// - les 3 callbacks (`onResend`, `onContinue`, `onChangeEmail`) sont
///   injectés par le routeur (slice D).
///
/// Le screen pur reste dumb pour conserver ses widget tests slice C.
class Au04EmailVerificationGate extends ConsumerStatefulWidget {
  /// Pour permettre `signUp` flow : redirige vers `/auth/signup`.
  final VoidCallback onChangeEmail;

  /// Manuel — l'utilisateur affirme avoir vérifié, on force un refetch
  /// session puis le routeur prend la suite.
  final VoidCallback onContinue;

  /// Email de fallback si le state n'est plus dispo (ex : navigation
  /// directe). Le state authNotifier prime quand il a un user.
  final String? fallbackEmail;

  const Au04EmailVerificationGate({
    super.key,
    required this.onChangeEmail,
    required this.onContinue,
    this.fallbackEmail,
  });

  @override
  ConsumerState<Au04EmailVerificationGate> createState() =>
      _Au04EmailVerificationGateState();
}

class _Au04EmailVerificationGateState
    extends ConsumerState<Au04EmailVerificationGate> {
  Timer? _poller;
  bool _continueFired = false;

  static const _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(_pollInterval, (_) => _pollSession());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  /// Appelle `refreshSession` via l'AuthRepository — si l'email vient
  /// d'être confirmé côté Supabase (`email_confirmed_at` non null), on
  /// quitte le gate automatiquement (Q2-C). Robuste aux échecs réseau :
  /// on swallow l'erreur et on retentera au prochain tick.
  Future<void> _pollSession() async {
    if (!mounted || _continueFired) return;
    try {
      final user = await ref.read(authRepositoryProvider).refreshSession();
      if (!mounted) return;
      if (user != null && user.isEmailVerified && !_continueFired) {
        _continueFired = true;
        widget.onContinue();
      }
    } catch (_) {
      // Le poll est best-effort — on retentera au prochain tick.
    }
  }

  Future<void> _resend() async {
    final email = _email;
    if (email == null) return;
    await ref
        .read(authNotifierProvider.notifier)
        .resendVerificationEmail(email: email);
  }

  String? get _email {
    final user = ref.read(authNotifierProvider).valueOrNull;
    return user?.email.value ?? widget.fallbackEmail;
  }

  @override
  Widget build(BuildContext context) {
    final email = _email ?? '';
    return Au04EmailVerificationScreen(
      email: email,
      onResend: _resend,
      onContinue: widget.onContinue,
      onChangeEmail: widget.onChangeEmail,
    );
  }
}
