import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/remembered_accounts_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Chips de suggestions de comptes déjà connectés sur ce poste.
///
/// Affiché au-dessus du champ email sur AU-01 — tap autofill l'email,
/// long-press propose de retirer le compte de la liste. Ne montre rien
/// quand la liste est vide ou en chargement.
class RememberedAccountsChips extends ConsumerWidget {
  /// Callback invoqué quand l'utilisateur tape un chip — fournit l'email
  /// à pré-remplir dans le formulaire.
  final ValueChanged<String> onTap;

  const RememberedAccountsChips({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(rememberedAccountsNotifierProvider);
    final emails = accounts.valueOrNull ?? const <String>[];
    if (emails.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMPTES RÉCENTS',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s2),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: [
            for (final email in emails)
              _AccountChip(
                email: email,
                onTap: () => onTap(email),
                onForget: () => ref
                    .read(rememberedAccountsNotifierProvider.notifier)
                    .forget(email),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }
}

class _AccountChip extends StatelessWidget {
  final String email;
  final VoidCallback onTap;
  final VoidCallback onForget;

  const _AccountChip({
    required this.email,
    required this.onTap,
    required this.onForget,
  });

  @override
  Widget build(BuildContext context) {
    // Audit TL PR #41 : afficher l'email complet (pas la troncature au
    // local-part), ellipsis si trop long. Évite la collision visuelle
    // entre deux providers partageant le même local-part (ex:
    // cherif@gmail.com vs cherif@outlook.com).
    return Semantics(
      button: true,
      label: 'Pré-remplir avec $email — tap sur la croix pour oublier',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: AppColors.borderEmphasis,
            width: AppBorderWidth.thin,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onTap,
                onLongPress: () => _showForgetSheet(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.pill),
                  bottomLeft: Radius.circular(AppRadius.pill),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s3,
                    AppSpacing.s2,
                    AppSpacing.s2,
                    AppSpacing.s2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.userRound,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      // ConstrainedBox + ellipsis : email complet visible
                      // mais bornée à ~180px pour rester compact dans le
                      // Wrap. Pas de troncature au local-part (collision
                      // visuelle, cf. audit TL).
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          email,
                          style: AppTypography.body,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bouton "x" explicite — affordance visible pour l'action
              // "oublier" (audit TL PR #41 : long-press seul = non
              // discoverable). Hit area 32x32 pour atteindre la cible
              // a11y minimale (~44px en comptant le padding du chip).
              Semantics(
                button: true,
                label: 'Oublier $email',
                child: InkWell(
                  onTap: () => _showForgetSheet(context),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppRadius.pill),
                    bottomRight: Radius.circular(AppRadius.pill),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.s1,
                      AppSpacing.s2,
                      AppSpacing.s3,
                      AppSpacing.s2,
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgetSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(email, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.s4),
              InkWell(
                onTap: () {
                  Navigator.of(ctx).pop();
                  onForget();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.trash2,
                        size: AppIconSize.md,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Text(
                        'Oublier ce compte',
                        style: AppTypography.body.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
