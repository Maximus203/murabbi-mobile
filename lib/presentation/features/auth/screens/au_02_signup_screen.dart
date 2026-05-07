import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/auth_error_banner.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// AU-02 — Inscription email + password (Q-18 : pas de pseudo, auto-généré
/// côté data layer). OAuth Google secondaire (P-6 ghost).
///
/// Navigation déléguée via callbacks (slice D wire go_router) :
/// - [onSignedUp] : déclenché quand `signUp` réussit (state.value != null).
///   Le routeur enchaîne sur AU-04 EmailVerification ou SETUP-01.
/// - [onSignIn] : lien "Se connecter" pour les utilisateurs déjà inscrits.
class Au02SignupScreen extends ConsumerStatefulWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignedUp;

  const Au02SignupScreen({
    super.key,
    required this.onSignIn,
    required this.onSignedUp,
  });

  @override
  ConsumerState<Au02SignupScreen> createState() => _Au02SignupScreenState();
}

class _Au02SignupScreenState extends ConsumerState<Au02SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    await ref
        .read(authNotifierProvider.notifier)
        .signUp(email: email, password: password);
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (_, next) {
      if (next.value != null) widget.onSignedUp();
    });

    final state = ref.watch(authNotifierProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const AppHeader.title(title: 'Créer un compte'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.s4),
              AppInput(
                label: 'Email',
                placeholder: 'vous@exemple.com',
                controller: _emailCtrl,
                leadingIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.s4),
              AppInput(
                label: 'Mot de passe',
                placeholder: '8 caractères minimum',
                controller: _passwordCtrl,
                leadingIcon: LucideIcons.lock,
                isPassword: true,
              ),
              if (state.hasError) ...[
                const SizedBox(height: AppSpacing.s3),
                AuthErrorBanner(failure: state.error),
              ],
              const SizedBox(height: AppSpacing.s4),
              AppButton(
                label: isLoading ? 'Création…' : 'Créer mon compte',
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.s3),
              AppButton(
                label: 'Continuer avec Google',
                onPressed: isLoading ? null : _signInWithGoogle,
                variant: AppButtonVariant.ghost,
              ),
              const SizedBox(height: AppSpacing.s5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Déjà un compte ? ',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : widget.onSignIn,
                    child: Text(
                      'Se connecter',
                      style: AppTypography.body.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
