import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/validate_auth_form_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/auth_error_banner.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/google_sign_in_button.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/remembered_accounts_chips.dart';
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
  final _validator = const AuthFormValidator();

  // #117 : erreurs de validation client affichées inline sous chaque champ.
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // #116 : purge tout état d'erreur hérité d'un autre écran auth (login ↔
    // signup ↔ forgot) à l'entrée. Post-frame : on ne modifie pas un
    // provider pendant la phase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authNotifierProvider.notifier).clearError();
    });
  }

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

    // #117 : validation synchrone AVANT tout appel réseau.
    final errors = _validator.validateLogin(email: email, password: password);
    setState(() {
      _emailError = errors.email;
      _passwordError = errors.password;
    });
    if (errors.hasErrors) return;

    await ref
        .read(authNotifierProvider.notifier)
        .signIn(email: email, password: password);
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  void _goToSignUp() {
    // #116 : nettoie l'erreur avant de naviguer vers signup.
    ref.read(authNotifierProvider.notifier).clearError();
    widget.onSignUp();
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
                    const SizedBox(height: AppSpacing.s6),
                    // Logo + Wordmark centré
                    const Center(child: AppWordmark(width: 140)),
                    // #120 : Spacer pondéré au-dessus du formulaire pour
                    // équilibrer l'espace vertical sans laisser un vide béant
                    // sous les champs.
                    const Spacer(),
                    RememberedAccountsChips(
                      onTap: (email) {
                        _emailCtrl.text = email;
                      },
                    ),
                    AppInput(
                      label: 'Email',
                      placeholder: 'vous@exemple.com',
                      controller: _emailCtrl,
                      leadingIcon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      errorText: _emailError,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    AppInput(
                      label: 'Mot de passe',
                      placeholder: '••••••••',
                      controller: _passwordCtrl,
                      leadingIcon: LucideIcons.lock,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _submit,
                      errorText: _passwordError,
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() => _passwordError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => widget.onForgotPassword(
                                _emailCtrl.text.trim(),
                              ),
                        child: Text(
                          'Mot de passe oublié ?',
                          style: AppTypography.body.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    if (state.hasError) ...[
                      const SizedBox(height: AppSpacing.s2),
                      AuthErrorBanner(failure: state.error),
                    ],
                    const SizedBox(height: AppSpacing.s5),
                    AppButton(
                      label: isLoading ? 'Connexion…' : 'Se connecter',
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    GoogleSignInButton(
                      onPressed: isLoading ? null : _signInWithGoogle,
                    ),
                    // #120 : Spacer pondéré sous le bloc CTA — distribue
                    // l'espace résiduel au lieu d'un grand vide unique.
                    const Spacer(),
                    const SizedBox(height: AppSpacing.s4),
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
                          onPressed: isLoading ? null : _goToSignUp,
                          child: Text(
                            'Créer un compte',
                            style: AppTypography.body.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
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
