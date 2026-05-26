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

/// ST-01 — Paramètres.
///
/// Sections : profil (tappable → ST-02) · COMPTE · PRATIQUE · CONFIDENTIALITÉ
/// · actions destructives (déconnexion / suppression compte).
///
/// Q-26 : la carte profil est à nouveau tappable pour ouvrir ST-02.
/// Pseudo et Nom complet sont en attente de décision PO (migration schema).
class St01SettingsScreen extends ConsumerWidget {
  /// Retour vers le dashboard.
  final VoidCallback onBack;

  /// Ouvre ST-02 (édition / lecture profil).
  final VoidCallback onEditProfile;

  /// Ouvre SA-02 — réglages horaires de prière.
  final VoidCallback onOpenPrayerSettings;

  /// Ouvre ST-03 — suppression de compte.
  final VoidCallback onDeleteAccount;

  /// Déconnexion confirmée.
  final VoidCallback onSignOut;

  const St01SettingsScreen({
    super.key,
    required this.onBack,
    required this.onEditProfile,
    required this.onOpenPrayerSettings,
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
          // ── Carte profil (tappable → ST-02) ─────────────────────────
          if (user != null) ...[
            _ProfileCard(user: user, onTap: onEditProfile),
            const SizedBox(height: AppSpacing.s5),
          ],

          // ── COMPTE ───────────────────────────────────────────────────
          _Section(
            title: 'COMPTE',
            tiles: [
              _SettingsTile(
                icon: LucideIcons.squarePen,
                label: 'Modifier le profil',
                onTap: onEditProfile,
              ),
              const _SettingsTile(
                icon: LucideIcons.bell,
                label: 'Notifications',
                trailing: 'Activées',
                onTap: null,
              ),
              const _SettingsTile(
                icon: LucideIcons.sun,
                label: 'Apparence',
                trailing: 'Clair',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── PRATIQUE ─────────────────────────────────────────────────
          _Section(
            title: 'PRATIQUE',
            tiles: [
              _SettingsTile(
                icon: LucideIcons.clock,
                label: 'Horaires de prière',
                // TODO(Q-26-B) : lire depuis prayerSettingsProvider
                trailing: 'MWL · Paris',
                onTap: onOpenPrayerSettings,
              ),
              _SettingsTile(
                icon: LucideIcons.star,
                label: 'Objectif quotidien',
                trailing: user != null ? '${user.level.dailyGoal} pts' : '—',
                onTap: null,
              ),
              const _SettingsTile(
                icon: LucideIcons.calendarDays,
                label: 'Démarrage de semaine',
                trailing: 'Lundi',
                onTap: null,
              ),
              const _SettingsTile(
                icon: LucideIcons.globe,
                label: 'Langue',
                trailing: 'Français',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── CONFIDENTIALITÉ ───────────────────────────────────────────
          const _Section(
            title: 'CONFIDENTIALITÉ',
            tiles: [
              _SettingsTile(
                icon: LucideIcons.lock,
                label: 'Politique de confidentialité',
                isExternalLink: true,
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Actions destructives ──────────────────────────────────────
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
        body: "Tu devras te reconnecter pour accéder à l'application.",
        confirmLabel: 'Se déconnecter',
        isDangerous: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
    if (confirmed ?? false) onSignOut();
  }
}

// ── Carte profil ──────────────────────────────────────────────────────────────

/// Carte profil : avatar initiale, pseudo canonique, email, badge niveau.
/// Tappable → ouvre ST-02. Issue Q-26.
class _ProfileCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const _ProfileCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final initial = user.pseudo.value.isEmpty
        ? '?'
        : user.pseudo.value.characters.first.toUpperCase();

    final levelOrdinal = user.level.index + 1;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppComponentSize.avatarMd,
            height: AppComponentSize.avatarMd,
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
                const SizedBox(height: AppSpacing.s2),
                _LevelBadge(ordinal: levelOrdinal, label: user.level.label),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            size: AppIconSize.md,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// Badge niveau — chip ocre avec icône étoile.
/// Affiche "Niveau X · Label" (ex. "Niveau 2 · Murīd").
class _LevelBadge extends StatelessWidget {
  final int ordinal;
  final String label;

  const _LevelBadge({required this.ordinal, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.star,
            size: AppIconSize.xs,
            color: AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.s1),
          Text(
            'Niveau $ordinal · $label',
            style: AppTypography.label.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────

/// Section de réglages : titre UPPERCASE + tuiles regroupées dans une seule
/// [AppCard] avec séparateurs internes.
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
          child: Text(
            title,
            style: AppTypography.label.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1)
                  const Divider(
                    height: AppBorderWidth.thin,
                    thickness: AppBorderWidth.thin,
                    color: AppColors.borderDefault,
                    indent: AppSpacing.s4,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tuile ─────────────────────────────────────────────────────────────────────

/// Tuile de réglage : icône · libellé · trailing optionnel · flèche / lien.
///
/// - [trailing] : valeur courante (ex. "Activées", "MWL · Paris").
/// - [isExternalLink] : icône lien externe à la place du chevron.
/// - [danger] : colore en [AppColors.danger].
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool danger;
  final bool isExternalLink;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.danger = false,
    this.isExternalLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.rg, color: color),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(color: color),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.s1),
            ],
            if (isExternalLink)
              const Icon(
                LucideIcons.externalLink,
                size: AppIconSize.sm,
                color: AppColors.textTertiary,
              )
            else if (onTap != null && !danger)
              const Icon(
                LucideIcons.chevronRight,
                size: AppIconSize.md,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
