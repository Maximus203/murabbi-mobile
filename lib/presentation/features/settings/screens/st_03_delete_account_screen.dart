import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/delete_account_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// Mot de confirmation exact attendu (règle S-10) — **sensible à la casse**.
const String kDeleteConfirmationWord = 'DELETE';

/// ST-03 — Supprimer le compte (issue #7, Phase 6).
///
/// Règle S-10 : confirmation par saisie exacte de "DELETE" (sensible à la
/// casse). Le bouton de suppression reste désactivé tant que la saisie ne
/// correspond pas exactement. Règle C-1 : suppression réelle (cf.
/// `DeleteAccountUseCase`), puis déconnexion + redirection login.
class St03DeleteAccountScreen extends ConsumerStatefulWidget {
  /// Retour vers ST-01.
  final VoidCallback onBack;

  /// Compte supprimé avec succès — le caller redirige vers login.
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

  /// Données supprimées — listées à l'utilisateur (RGPD, transparence).
  static const List<String> _deletedData = [
    'Ton profil et tes informations personnelles',
    'Toutes tes habitudes et leur historique',
    'Tes collections et invocations enregistrées',
    'Ta progression, ton score et ton niveau',
  ];

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// `true` uniquement si la saisie correspond EXACTEMENT (casse comprise).
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
          const Text(
            'Cette action est irréversible',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'La suppression de ton compte effacera définitivement :',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s4),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in _deletedData) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.x,
                        size: AppIconSize.sm,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(child: Text(item, style: AppTypography.body)),
                    ],
                  ),
                  if (item != _deletedData.last)
                    const SizedBox(height: AppSpacing.s3),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          const Text(
            'Pour confirmer, saisis $kDeleteConfirmationWord ci-dessous.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(
            placeholder: kDeleteConfirmationWord,
            controller: _confirmCtrl,
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.s6),
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
