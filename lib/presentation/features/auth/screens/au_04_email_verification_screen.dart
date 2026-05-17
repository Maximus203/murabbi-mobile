import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// AU-04 — Vérification d'email post-signup.
///
/// MVP slice C : écran statelessful avec 3 callbacks.
/// L'auto-poll session (refetch `getCurrentUser` toutes les N secondes pour
/// détecter l'email vérifié côté Supabase) est délégué à la couche routing
/// de slice D, qui pourra invalider `authNotifierProvider` sur un timer ou
/// brancher un deep-link `auth/callback`.
///
/// Limitation connue : pas de timer ici — l'utilisateur doit tap
/// "J'ai vérifié mon email" pour confirmer manuellement.
class Au04EmailVerificationScreen extends StatefulWidget {
  /// Email auquel le mail de vérification a été envoyé. Affiché à l'écran.
  final String email;

  /// Renvoie le mail de vérification (idempotent côté Supabase). Le screen
  /// gère lui-même l'état pending → success ('Email renvoyé').
  final Future<void> Function() onResend;

  /// Confirme manuellement la vérification (route vers SETUP-01 ou HM-01).
  final VoidCallback onContinue;

  /// Permet de revenir à AU-02 pour saisir une autre adresse.
  final VoidCallback onChangeEmail;

  const Au04EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onResend,
    required this.onContinue,
    required this.onChangeEmail,
  });

  @override
  State<Au04EmailVerificationScreen> createState() =>
      _Au04EmailVerificationScreenState();
}

class _Au04EmailVerificationScreenState
    extends State<Au04EmailVerificationScreen> {
  bool _resending = false;
  bool _resentOnce = false;

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await widget.onResend();
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
          _resentOnce = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Vérifie ton email',
        onBack: widget.onChangeEmail,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s5,
              vertical: AppSpacing.s4,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.s5),
                    const _MailIllustration(),
                    const SizedBox(height: AppSpacing.s5),
                    Text(
                      'Nous t\'avons envoyé un lien de vérification à :',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      widget.email,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Ouvre l\'email et clique sur le lien pour activer ton compte. Pense à vérifier les spams.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_resentOnce) ...[
                      const SizedBox(height: AppSpacing.s4),
                      _ResentBanner(),
                    ],
                    const Spacer(),
                    const SizedBox(height: AppSpacing.s5),
                    AppButton(
                      label: 'J\'ai vérifié mon email',
                      onPressed: _resending ? null : widget.onContinue,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    AppButton(
                      label: _resending ? 'Envoi…' : 'Renvoyer l\'email',
                      onPressed: _resending ? null : _resend,
                      variant: AppButtonVariant.ghost,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    TextButton(
                      onPressed: _resending ? null : widget.onChangeEmail,
                      child: Text(
                        'Changer d\'adresse',
                        style: AppTypography.body.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MailIllustration extends StatelessWidget {
  const _MailIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25),
            width: AppBorderWidth.thin,
          ),
        ),
        child: const Icon(
          LucideIcons.mailCheck,
          size: 36,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _ResentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circleCheck,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              'Email renvoyé. Vérifie ta boîte (et les spams).',
              style: AppTypography.body.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
