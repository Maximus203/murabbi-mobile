import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

// Issue #168 — `pseudo` est désormais immuable côté serveur (admin#125 :
// la RPC `update_user_pseudo` lève `PSEUDO_IMMUTABLE`). Côté UI, on a
// retiré toute affordance d'édition du pseudo (carte profil non tappable,
// section "Compte" retirée). Le callback `onEditProfile` du constructeur
// est conservé pour rétro-compatibilité du routeur mais n'est plus câblé.

/// ST-01 — Écran Paramètres (issue #7, Phase 6).
///
/// Card profil (avatar initiale, pseudo, email, niveau) + sections
/// Compte / Pratique / Confidentialité / À propos, déconnexion et accès à
/// la suppression de compte.
class St01SettingsScreen extends ConsumerWidget {
  /// Retour vers l'écran précédent (dashboard).
  final VoidCallback onBack;

  /// Ouvre ST-02 — désormais écran lecture seule (#168). Conservé pour
  /// rétro-compatibilité du routeur mais l'écran ST-01 ne déclenche plus
  /// cette navigation.
  final VoidCallback onEditProfile;

  /// Ouvre ST-03 — suppression de compte.
  final VoidCallback onDeleteAccount;

  /// Déconnexion confirmée.
  final VoidCallback onSignOut;

  const St01SettingsScreen({
    super.key,
    required this.onBack,
    required this.onEditProfile,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: 'Paramètres', onBack: onBack),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          // Issue #168 — la carte profil n'est plus tappable (pseudo
          // immuable côté serveur, plus rien à éditer en self-service).
          if (user != null) _ProfileCard(user: user),
          const SizedBox(height: AppSpacing.s5),
          const _Section(
            title: 'Pratique',
            tiles: [
              _SettingsTile(
                icon: LucideIcons.bell,
                label: 'Notifications',
                // Réglages notifications gérés via SA-02 (plages horaires).
                onTap: null,
              ),
            ],
          ),
          const _Section(
            title: 'Confidentialité',
            tiles: [
              _SettingsTile(
                icon: LucideIcons.shield,
                label: 'Données personnelles',
                onTap: null,
              ),
            ],
          ),
          const _Section(
            title: 'À propos',
            tiles: [
              _SettingsTile(
                icon: LucideIcons.info,
                label: 'Version de l\'application',
                trailing: '1.0.0',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          _SettingsTile(
            icon: LucideIcons.logOut,
            label: 'Se déconnecter',
            onTap: () => _confirmSignOut(context),
          ),
          const SizedBox(height: AppSpacing.s2),
          _SettingsTile(
            icon: LucideIcons.trash2,
            label: 'Supprimer le compte',
            danger: true,
            onTap: onDeleteAccount,
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Se déconnecter ?',
        body: 'Tu devras te reconnecter pour accéder à l\'application.',
        confirmLabel: 'Se déconnecter',
        isDangerous: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
    if (confirmed ?? false) onSignOut();
  }
}

/// Carte profil : avatar initiale, pseudo (`pseudo#XXXX` via
/// [User.displayPseudo]), email, niveau. Issue #168 — non tappable.
class _ProfileCard extends StatelessWidget {
  final User user;

  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    // L'avatar reste dérivé du pseudo brut (sans le suffixe #XXXX).
    final initial = user.pseudo.value.isEmpty
        ? '?'
        : user.pseudo.value.characters.first.toUpperCase();

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.h2.copyWith(color: AppColors.bgSurface),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayPseudo, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  user.email.value,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  'Niveau · ${user.level.label}',
                  style: AppTypography.label.copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section de réglages avec titre + tuiles.
class _Section extends StatelessWidget {
  final String title;
  final List<_SettingsTile> tiles;

  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.s1,
            bottom: AppSpacing.s2,
          ),
          child: Text(title.toUpperCase(), style: AppTypography.label),
        ),
        ...tiles,
      ],
    );
  }
}

/// Tuile de réglage — icône, libellé, trailing optionnel.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool danger;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(color: color),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              )
            else if (onTap != null)
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
