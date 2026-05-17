import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habit_detail_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_log_history_tile.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_stat_card.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/heatmap_30.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// HB-DETAIL — Écran détail d'une habitude (issue #153).
///
/// Affiche le header (nom + actions), 3 [HabitStatCard] (série, record,
/// taux 30j), la [Heatmap30] des 30 derniers jours, et la section historique
/// des 7 derniers logs.
///
/// Les stats sont calculées par `GetHabitStatsUseCase` (domain pur, #148)
/// via le `HabitDetailNotifier`.
class HbDetailScreen extends ConsumerWidget {
  /// Identifiant de l'habitude affichée.
  final String habitId;

  /// Navigation retour (← header).
  final VoidCallback onBack;

  /// Ouvre HA-02 en mode édition pour [habitId].
  final void Function(String habitId) onEdit;

  /// Appelé après une suppression réussie — l'appelant quitte l'écran.
  final VoidCallback onDeleted;

  const HbDetailScreen({
    super.key,
    required this.habitId,
    required this.onBack,
    required this.onEdit,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(habitDetailNotifierProvider(habitId));

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: detail.valueOrNull?.habit.name.value ?? 'Habitude',
        onBack: onBack,
        trailing: detail.valueOrNull == null
            ? null
            : IconButton(
                key: const Key('hb_detail_menu'),
                tooltip: 'Options',
                splashRadius: 18,
                onPressed: () => _showActionsSheet(context, ref),
                icon: const Icon(
                  LucideIcons.ellipsisVertical,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
      body: detail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(habitDetailNotifierProvider(habitId)),
        ),
        data: (state) => _DetailContent(state: state),
      ),
    );
  }

  /// Bottom sheet d'actions — Modifier / Supprimer.
  void _showActionsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('hb_detail_action_edit'),
                leading: const Icon(
                  LucideIcons.pencil,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                title: const Text('Modifier', style: AppTypography.body),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEdit(habitId);
                },
              ),
              ListTile(
                key: const Key('hb_detail_action_delete'),
                leading: const Icon(
                  LucideIcons.trash2,
                  size: 20,
                  color: AppColors.danger,
                ),
                title: Text(
                  'Supprimer',
                  style: AppTypography.body.copyWith(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog de confirmation de suppression.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Supprimer cette habitude ?',
        body: "Cette action est définitive. L'historique sera perdu.",
        confirmLabel: 'Supprimer',
        isDangerous: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(habitDetailNotifierProvider(habitId).notifier)
          .deleteHabit();
      onDeleted();
    } catch (e, st) {
      appLog.e('deleteHabit failed', error: e, stackTrace: st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la suppression.')),
        );
      }
    }
  }
}

/// Contenu principal — stats + heatmap + historique.
class _DetailContent extends StatelessWidget {
  final HabitDetailState state;

  const _DetailContent({required this.state});

  /// Taux 30j formaté en pourcentage entier.
  String get _ratePercent => '${(state.stats.rate30Days * 100).round()} %';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        // ── Section Stats ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: HabitStatCard(
                icon: LucideIcons.flame,
                value: '${state.stats.currentStreak} j',
                label: 'Série actuelle',
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: HabitStatCard(
                icon: LucideIcons.trophy,
                value: '${state.stats.recordStreak} j',
                label: 'Record',
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: HabitStatCard(
                icon: LucideIcons.chartLine,
                value: _ratePercent,
                label: 'Taux 30 jours',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),

        // ── Section Heatmap ──────────────────────────────────────────
        const Text('30 derniers jours', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.s4),
        AppCard(child: Heatmap30(heatmapData: state.stats.heatmapData)),
        const SizedBox(height: AppSpacing.s6),

        // ── Section Historique ───────────────────────────────────────
        const Text('Historique', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.s2),
        if (state.recentLogs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            child: Text(
              'Aucun log pour le moment.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s1,
            ),
            child: Column(
              children: [
                for (final log in state.recentLogs)
                  HabitLogHistoryTile(log: log),
              ],
            ),
          ),
      ],
    );
  }
}

/// État d'erreur avec action de réessai.
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.circleAlert,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Impossible de charger cette habitude.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
