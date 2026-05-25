import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/use_cases/auth/validate_auth_form_use_case.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/auth_error_banner.dart';
import 'package:murabbi_mobile/presentation/features/auth/widgets/google_sign_in_button.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// AU-02 — Inscription nom + email + password. OAuth Google secondaire.
///
/// #131 : le champ « Nom » est requis et devient le `pseudo` du profil
/// (fini le placeholder « Anonyme #xxxx »).
///
/// Navigation déléguée via callbacks (slice D wire go_router) :
/// - [onSignedUp] : déclenché quand `signUp` réussit (state.value != null).
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
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _validator = const AuthFormValidator();

  // #117 : erreurs de validation client affichées inline sous chaque champ.
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // #116 : purge tout état d'erreur hérité du login à l'entrée du signup.
    // Post-frame : on ne modifie pas un provider pendant la phase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authNotifierProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final displayName = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // #117 : validation synchrone AVANT tout appel réseau.
    final errors = _validator.validateSignup(
      displayName: displayName,
      email: email,
      password: password,
    );
    setState(() {
      _nameError = errors.displayName;
      _emailError = errors.email;
      _passwordError = errors.password;
    });
    if (errors.hasErrors) return;

    await ref
        .read(authNotifierProvider.notifier)
        .signUp(email: email, password: password, displayName: displayName);
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
  }

  void _goToSignIn() {
    // #116 : nettoie l'erreur avant de revenir au login.
    ref.read(authNotifierProvider.notifier).clearError();
    widget.onSignIn();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (_, next) {
      if (next.valueOrNull != null) widget.onSignedUp();
    });

    final state = ref.watch(authNotifierProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: 'Créer un compte', onBack: _goToSignIn),
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
                    const SizedBox(height: AppSpacing.s4),
                    // #131 : champ Nom requis — devient le pseudo du profil.
                    AppInput(
                      label: 'Nom',
                      placeholder: 'Ton prénom ou pseudo',
                      controller: _nameCtrl,
                      leadingIcon: LucideIcons.user,
                      textInputAction: TextInputAction.next,
                      maxLength: 30,
                      errorText: _nameError,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.s4),
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
                      placeholder: 'Au moins 8 caractères',
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
                    if (state.hasError) ...[
                      const SizedBox(height: AppSpacing.s3),
                      AuthErrorBanner(failure: state.error),
                    ],
                    // #120 : Spacer pondéré au lieu d'un vide béant.
                    const Spacer(),
                    const SizedBox(height: AppSpacing.s5),
                    AppButton(
                      label: isLoading ? 'Création…' : 'Créer mon compte',
                      onPressed: isLoading ? null : _submit,
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    GoogleSignInButton(
                      onPressed: isLoading ? null : _signInWithGoogle,
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
                          onPressed: isLoading ? null : _goToSignIn,
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
