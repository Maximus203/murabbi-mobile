import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/edit_profile_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// ST-02 — Mon profil.
///
/// Affiche les informations de profil selon le wireframe validé.
///
/// ## État des champs (Q-26 — décision PO attendue)
///
/// - **Nom complet** : read-only jusqu'à la migration `display_name` dans
///   `users` v1.3.x (aucune colonne actuellement).
/// - **Email** : verrouillé Supabase Auth — toujours read-only.
/// - **Pseudonyme (classement)** : read-only per issue #168 (`pseudo_immutable_trigger`).
///
/// Le bouton "Enregistrer" est présent (wireframe) mais désactivé.
/// Il sera activé par tranche, en parallèle des migrations schema.
class St02EditProfileScreen extends ConsumerStatefulWidget {
  /// Retour vers ST-01.
  final VoidCallback onBack;

  /// Profil sauvegardé avec succès (réservé pour les futures tranches).
  final VoidCallback onSaved;

  const St02EditProfileScreen({
    super.key,
    required this.onBack,
    required this.onSaved,
  });

  @override
  ConsumerState<St02EditProfileScreen> createState() =>
      _St02EditProfileScreenState();
}

class _St02EditProfileScreenState extends ConsumerState<St02EditProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final saving = ref.watch(editProfileNotifierProvider).isLoading;

    final displayPseudo = user?.displayPseudo ?? '—';
    final email = user?.email.value ?? '—';
    final initial = (user?.pseudo.value.isNotEmpty ?? false)
        ? user!.pseudo.value.characters.first.toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: 'Mon profil', onBack: widget.onBack),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          // ── Avatar ────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: AppComponentSize.avatarLg,
                  height: AppComponentSize.avatarLg,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: AppTypography.display.copyWith(
                      color: AppColors.bgSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                // Q-26 : feature photo non déployée — no-op.
                GestureDetector(
                  onTap: () =>
                      appLog.d('ST-02 : Modifier la photo — Q-26 pending'),
                  child: Text(
                    'Modifier la photo',
                    style: AppTypography.body.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Nom complet (Q-26 — migration display_name requise) ────────
          const _FieldLabel(label: 'Nom complet'),
          const SizedBox(height: AppSpacing.s1),
          _ReadOnlyField(value: displayPseudo, hint: 'Ton nom complet'),
          const SizedBox(height: AppSpacing.s4),

          // ── Email (verrouillé Supabase Auth) ──────────────────────────
          const _FieldLabel(label: 'Email'),
          const SizedBox(height: AppSpacing.s1),
          _ReadOnlyField(value: email, hint: 'Email', showLock: true),
          const SizedBox(height: AppSpacing.s4),

          // ── Pseudonyme classement (Q-26 — issue #168) ─────────────────
          const _FieldLabel(label: 'Pseudonyme (classement)'),
          const SizedBox(height: AppSpacing.s1),
          _ReadOnlyField(
            value: user?.pseudo.value ?? '—',
            hint: 'Pseudonyme',
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            'Apparaîtra publiquement sur le classement.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),

          // ── Enregistrer (désactivé — Q-26 en attente) ─────────────────
          AppButton(
            label: saving ? 'Enregistrement…' : 'Enregistrer',
            variant: AppButtonVariant.primary,
            // ignore: avoid_redundant_argument_values
            onPressed: null, // activé quand Q-26 résolu
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

/// Label de champ — style `label` secondaire.
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

/// Champ en lecture seule visuellement cohérent avec AppInput désactivé.
/// [showLock] ajoute l'icône cadenas (champ Email).
class _ReadOnlyField extends StatelessWidget {
  final String value;
  final String hint;
  final bool showLock;

  const _ReadOnlyField({
    required this.value,
    required this.hint,
    this.showLock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (showLock)
            const Icon(
              LucideIcons.lock,
              size: AppIconSize.sm,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}
