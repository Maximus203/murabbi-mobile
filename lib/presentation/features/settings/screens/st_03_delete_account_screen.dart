import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/delete_account_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// Mot de confirmation exact attendu (règle S-10) — **sensible à la casse**.
const String kDeleteConfirmationWord = 'DELETE';

/// ST-03 — Supprimer le compte.
///
/// Règle S-10 : confirmation par saisie exacte de "DELETE" (sensible à la
/// casse). Bouton désactivé tant que la saisie ne correspond pas.
///
/// Le wireframe impose :
/// - Icône ⚠ sur fond danger translucide (cercle).
/// - Titre "Cette action est irréversible." (avec point final).
/// - Carte DONNÉES SUPPRIMÉES fond danger translucide + bordure danger.
/// - Items de données précis (libellés wireframe).
/// - Label "Saisissez DELETE pour confirmer" au-dessus du champ.
/// - Bouton "Supprimer définitivement" destructif.
class St03DeleteAccountScreen extends ConsumerStatefulWidget {
  /// Retour vers ST-01.
  final VoidCallback onBack;

  /// Compte supprimé — caller redirige vers login.
  final VoidCallback onDeleted;

  const St03DeleteAccountScreen({
    super.key,
    required this.onBack,
    required this.onDeleted,
  });

  @override
  ConsumerState<St03DeleteAccountScreen> createState() =>
      _St03DeleteAccountScreenState();
}

class _St03DeleteAccountScreenState
    extends ConsumerState<St03DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  String? _error;

  /// Données supprimées — libellés exacts du wireframe ST-03.
  static const List<String> _deletedData = [
    'Profil, identifiants, photo',
    'Historique des prières et habitudes',
    'Collections personnelles',
    'Score, streaks et classements',
  ];

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canDelete => _confirmCtrl.text == kDeleteConfirmationWord;

  Future<void> _delete() async {
    setState(() => _error = null);
    final ok = await ref
        .read(deleteAccountNotifierProvider.notifier)
        .deleteCurrentAccount();
    if (!mounted) return;
    if (ok) {
      widget.onDeleted();
    } else {
      setState(() => _error = 'La suppression a échoué. Réessaie plus tard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deleting = ref.watch(deleteAccountNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Supprimer le compte',
        onBack: widget.onBack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          // ── Icône avertissement ───────────────────────────────────────
          Center(
            child: Container(
              width: AppComponentSize.podiumCol,
              height: AppComponentSize.podiumCol,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.triangleAlert,
                size: AppIconSize.lg,
                color: AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s5),

          // ── Titre ─────────────────────────────────────────────────────
          const Text(
            'Cette action est irréversible.',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            "Votre compte et l'ensemble de vos données seront supprimés "
            'sous 30 jours. Aucune restauration ne sera possible.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s5),

          // ── Carte DONNÉES SUPPRIMÉES ───────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
                width: AppBorderWidth.thin,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DONNÉES SUPPRIMÉES',
                  style: AppTypography.label.copyWith(
                    color: AppColors.danger,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                for (final item in _deletedData) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(
                          top: AppSpacing.s1,
                          right: AppSpacing.s2,
                        ),
                        width: AppComponentSize.dotSize,
                        height: AppComponentSize.dotSize,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item != _deletedData.last)
                    const SizedBox(height: AppSpacing.s2),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Champ de confirmation ─────────────────────────────────────
          Text(
            'Saisissez $kDeleteConfirmationWord pour confirmer',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(
            placeholder: kDeleteConfirmationWord,
            controller: _confirmCtrl,
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Bouton destructif ─────────────────────────────────────────
          AppButton(
            label: deleting ? 'Suppression…' : 'Supprimer définitivement',
            variant: AppButtonVariant.destructive,
            onPressed: (deleting || !_canDelete) ? null : _delete,
          ),
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            label: 'Annuler',
            variant: AppButtonVariant.ghost,
            onPressed: deleting ? null : widget.onBack,
          ),
        ],
      ),
    );
  }
}
