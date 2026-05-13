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

  String get _display {
    // "abc@example.com" → "abc" pour économiser de l'espace dans le chip.
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return email;
    return email.substring(0, atIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pré-remplir avec $email — appui long pour oublier',
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showForgetSheet(context),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s2,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: AppColors.borderEmphasis,
              width: AppBorderWidth.thin,
            ),
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
              Text(_display, style: AppTypography.body),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s3),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      SizedBox(width: AppSpacing.s3),
                      Text(
                        'Oublier ce compte',
                        style: TextStyle(color: AppColors.danger),
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
