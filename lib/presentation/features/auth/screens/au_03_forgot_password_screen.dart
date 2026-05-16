import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// AU-03 — Mot de passe oublié.
///
/// Q-7 / OWASP anti-enumeration : l'écran affiche TOUJOURS le même message
/// de succès générique ("Si un compte existe pour cette adresse, un lien a
/// été envoyé"), que l'email soit connu ou inconnu. Le `bool` retourné par
/// [AuthNotifier.sendPasswordReset] est ignoré côté UI (utilisé uniquement
/// pour télémétrie / retry futur).
class Au03ForgotPasswordScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  /// Email pré-rempli transmis depuis AU-01 (AU-03 UX).
  final String? initialEmail;

  const Au03ForgotPasswordScreen({
    super.key,
    required this.onBack,
    this.initialEmail,
  });

  @override
  ConsumerState<Au03ForgotPasswordScreen> createState() =>
      _Au03ForgotPasswordScreenState();
}

class _Au03ForgotPasswordScreenState
    extends ConsumerState<Au03ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _submitted = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail?.isNotEmpty == true) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final email = _emailCtrl.text.trim();
    // bool ignoré côté UI — Q-7 anti-enumeration.
    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(email: email);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Mot de passe oublié',
        onBack: widget.onBack,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          child: _submitted
              ? _SuccessView(onBack: widget.onBack)
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Entre l\'email associé à ton compte. Nous t\'enverrons un lien pour réinitialiser ton mot de passe (valide 15 minutes).',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s5),
        AppInput(
          label: 'Email',
          placeholder: 'vous@exemple.com',
          controller: _emailCtrl,
          leadingIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.s5),
        AppButton(
          label: _submitting ? 'Envoi…' : 'Envoyer le lien',
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onBack;
  const _SuccessView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s5),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: AppBorderWidth.thin,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.circleCheck,
                    size: 22,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    'Lien envoyé',
                    style: AppTypography.h3.copyWith(color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                'Si un compte existe pour cette adresse, un email vient de partir avec un lien valide 15 minutes. Pense à vérifier les spams.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        AppButton(label: 'Retour à la connexion', onPressed: onBack),
      ],
    );
  }
}
