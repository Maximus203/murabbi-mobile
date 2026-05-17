import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/auth_error_banner.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';
import 'package:murabbi_mobile/presentation/widgets/app_logo.dart';

/// AU-01 — Connexion email + password + Google OAuth.
///
/// Navigation déléguée via callbacks (slice D les branche sur go_router).
class Au01LoginScreen extends ConsumerStatefulWidget {
  /// Appelé avec l'email saisi quand l'utilisateur tape "Mot de passe oublié".
  final ValueChanged<String> onForgotPassword;
  final VoidCallback onSignUp;
  final VoidCallback onAuthenticated;

  const Au01LoginScreen({
    super.key,
    required this.onForgotPassword,
    required this.onSignUp,
    required this.onAuthenticated,
  });

  @override
  ConsumerState<Au01LoginScreen> createState() => _Au01LoginScreenState();
}

class _Au01LoginScreenState extends ConsumerState<Au01LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    await ref
        .read(authNotifierProvider.notifier)
        .signIn(email: email, password: password);
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (_, next) {
      if (next.value != null) widget.onAuthenticated();
    });

    final state = ref.watch(authNotifierProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header compact : logo + wordmark en ligne
              Row(
                children: [
                  const AppLogo(size: 28),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    'Murabbi',
                    style: AppTypography.label.copyWith(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              // Titre d'écran
              const Text('Bon retour.', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Reprenez votre pratique là où vous l\'aviez laissée.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              // Formulaire avec autofill natif
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppInput(
                      label: 'Email',
                      placeholder: 'vous@exemple.com',
                      controller: _emailCtrl,
                      leadingIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    AppInput(
                      label: 'Mot de passe',
                      placeholder: '••••••••',
                      controller: _passwordCtrl,
                      leadingIcon: LucideIcons.lock,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: isLoading ? null : _submit,
                      autofillHints: const [AutofillHints.password],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isLoading
                      ? null
                      : () => widget.onForgotPassword(_emailCtrl.text.trim()),
                  child: Text(
                    'Mot de passe oublié ?',
                    style: AppTypography.body.copyWith(color: AppColors.accent),
                  ),
                ),
              ),
              if (state.hasError) ...[
                const SizedBox(height: AppSpacing.s2),
                AuthErrorBanner(failure: state.error),
              ],
              const SizedBox(height: AppSpacing.s6),
              AppButton(
                label: isLoading ? 'Connexion…' : 'Se connecter',
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.s4),
              // Séparateur OU
              Row(
                children: [
                  const Expanded(child: Divider(thickness: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                    ),
                    child: Text(
                      'OU',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(thickness: 0.5)),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              AppButton(
                label: 'Continuer avec Google',
                onPressed: isLoading ? null : _signInWithGoogle,
                variant: AppButtonVariant.secondary,
                leadingWidget: SvgPicture.asset(
                  'assets/images/logo_google.svg',
                  width: 18,
                  height: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : widget.onSignUp,
                    child: Text(
                      'Créer',
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
