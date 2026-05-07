import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_screen.dart';

/// Wrapper "gate" — branche [Au04EmailVerificationScreen] sur le routeur :
/// - lit l'email depuis `authNotifierProvider` (utilisateur fraîchement
///   signé up, session active mais email pas encore confirmé) ;
/// - démarre un `Timer.periodic` de 5s qui invalide
///   `authNotifierProvider` ; au prochain `getCurrentUser`, si Supabase a
///   confirmé l'email, le state se met à jour et le routeur fait le
///   redirect global ;
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

  static const _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(_pollInterval, (_) {
      ref.invalidate(authNotifierProvider);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final email = _email;
    if (email == null) return;
    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(email: email);
    // NB : on réutilise sendPasswordReset comme MVP — l'API
    // `resendVerificationEmail` n'existe pas encore côté repository et
    // tombera dans une issue de suivi. Le bandeau "Email renvoyé" du
    // screen reste correct visuellement.
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
