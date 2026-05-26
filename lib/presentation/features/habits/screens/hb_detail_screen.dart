import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habit_detail_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_log_history_tile.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_objective_sheet.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_stat_card.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_timer_sheet.dart';
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
                  size: AppIconSize.rg,
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
        data: (state) => _DetailContent(state: state, habitId: habitId),
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
                  size: AppIconSize.rg,
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
                  size: AppIconSize.rg,
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

/// Contenu principal — section objectif/timer (selon target) + stats + heatmap + historique.
class _DetailContent extends ConsumerWidget {
  final HabitDetailState state;
  final String habitId;

  const _DetailContent({required this.state, required this.habitId});

  String get _ratePercent => '${(state.stats.rate30Days * 100).round()} %';

  /// Log d'aujourd'hui (UTC), null si pas encore loggué.
  int? get _todayActualValue {
    final today = DateTime.now().toUtc();
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    for (final log in state.recentLogs) {
      if (log.date == todayDate) return log.actualValue;
    }
    return null;
  }

  Future<void> _log(
    WidgetRef ref, {
    required int actualValue,
    required int targetValue,
    Duration? duration,
  }) async {
    final today = DateTime.now().toUtc();
    await ref
        .read(logHabitValueUseCaseProvider)
        .call(
          habitId: HabitId(habitId),
          date: DateTime.utc(today.year, today.month, today.day),
          actualValue: actualValue,
          targetValue: targetValue,
          duration: duration,
        );
    await ref
        .read(habitDetailNotifierProvider(habitId).notifier)
        .refreshStats();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        // ── Section Objectif / Timer (selon le type de target) ───────
        ..._targetSection(context, ref),

        // ── Section Stats ─────────────────────────────────────────────
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

        // ── Section Heatmap ───────────────────────────────────────────
        const Text('30 derniers jours', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.s4),
        AppCard(child: Heatmap30(heatmapData: state.stats.heatmapData)),
        const SizedBox(height: AppSpacing.s6),

        // ── Section Historique ────────────────────────────────────────
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

  List<Widget> _targetSection(BuildContext context, WidgetRef ref) {
    final target = state.habit.target;
    return switch (target) {
      HabitTargetValue() => [
        _ObjectiveCard(
          target: target,
          currentValue: _todayActualValue,
          onTap: () => showHabitObjectiveSheet(
            context,
            target: target,
            currentValue: _todayActualValue,
            onValidate: (value) =>
                _log(ref, actualValue: value, targetValue: target.value.value),
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
      ],
      HabitTargetTimed() => [
        _TimerCard(
          target: target,
          alreadyDone: _todayActualValue != null,
          onTap: () => showHabitTimerSheet(
            context,
            habit: state.habit,
            target: target,
            onValidate: (elapsed) {
              final actualValue = target.unit == TargetUnit.hours
                  ? elapsed.inSeconds ~/ 3600
                  : elapsed.inMinutes;
              _log(
                ref,
                actualValue: actualValue,
                targetValue: target.value.value,
                duration: elapsed,
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
      ],
      HabitTargetNone() => const [],
    };
  }
}

// ── Carte Objectif chiffré ─────────────────────────────────────────────────────

class _ObjectiveCard extends StatelessWidget {
  final HabitTargetValue target;
  final int? currentValue;
  final VoidCallback onTap;

  const _ObjectiveCard({
    required this.target,
    required this.currentValue,
    required this.onTap,
  });

  int get _targetValue => target.value.value;
  int get _actual => currentValue ?? 0;
  bool get _done => _actual >= _targetValue;

  String get _unitLabel {
    if (target.unit == TargetUnit.custom) return target.customLabel ?? '';
    return _unitName(target.unit);
  }

  Color get _valueColor {
    if (_actual > _targetValue) return AppColors.success;
    if (_actual >= _targetValue) return AppColors.accent;
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Objectif du jour',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (_done)
                const Icon(
                  LucideIcons.circleCheck,
                  size: AppIconSize.md,
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_actual',
                style: AppTypography.h1.copyWith(
                  fontSize: 40,
                  color: _valueColor,
                ),
              ),
              Text(
                ' / $_targetValue $_unitLabel',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.indicator),
            child: LinearProgressIndicator(
              value: (_actual / _targetValue).clamp(0.0, 1.0),
              backgroundColor: AppColors.bgInput,
              color: _done ? AppColors.success : AppColors.accent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            label: _done ? '✓ Mis à jour' : 'Mettre à jour la valeur',
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

// ── Carte Timer ────────────────────────────────────────────────────────────────

class _TimerCard extends StatelessWidget {
  final HabitTargetTimed target;
  final bool alreadyDone;
  final VoidCallback onTap;

  const _TimerCard({
    required this.target,
    required this.alreadyDone,
    required this.onTap,
  });

  String get _targetLabel {
    final v = target.value.value;
    final unit = target.unit == TargetUnit.hours ? 'h' : 'min';
    return '$v $unit';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timer',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (alreadyDone)
                const Icon(
                  LucideIcons.circleCheck,
                  size: AppIconSize.md,
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              const Icon(LucideIcons.timer, size: AppIconSize.semilg, color: AppColors.accent),
              const SizedBox(width: AppSpacing.s3),
              Text(
                _targetLabel,
                style: AppTypography.h1.copyWith(fontSize: 32),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            label: alreadyDone ? 'Refaire le timer' : 'Démarrer le timer',
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

// ── Utilitaire ─────────────────────────────────────────────────────────────────

String _unitName(TargetUnit unit) {
  switch (unit) {
    case TargetUnit.minutes:
      return 'min';
    case TargetUnit.hours:
      return 'h';
    case TargetUnit.pages:
      return 'pages';
    case TargetUnit.glasses:
      return 'verres';
    case TargetUnit.reps:
      return 'rép.';
    case TargetUnit.sets:
      return 'séries';
    case TargetUnit.km:
      return 'km';
    case TargetUnit.meters:
      return 'm';
    case TargetUnit.steps:
      return 'pas';
    case TargetUnit.custom:
      return '';
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
              size: AppComponentSize.iconTile,
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
