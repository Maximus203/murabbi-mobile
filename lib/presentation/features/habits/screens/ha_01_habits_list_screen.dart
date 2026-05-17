import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_logo.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';

/// HA-01 — Liste des habitudes de l'utilisateur (slice 3.D).
///
/// Affichage simple : nom + nombre de points + récurrence textuelle.
/// FAB "Nouvelle habitude" déclenche [onCreate]. Empty state si aucune
/// habitude.
class Ha01HabitsListScreen extends ConsumerWidget {
  final VoidCallback onCreate;

  const Ha01HabitsListScreen({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const AppHeader.title(title: 'Habitudes'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: AppButton(label: 'Nouvelle habitude', onPressed: onCreate),
        ),
      ),
      body: habits.when(
        // D-28 : skeleton list à la place du spinner seul pendant le chargement.
        loading: () => const _SkeletonLoadingView(),
        error: (e, stackTrace) {
          // Audit TL §B.2 PR #43 : pas de `e.toString()` brut en UI.
          // Détail loggé via appLog, libellé canonique FR.
          appLog.e(
            'Ha01HabitsListScreen render error',
            error: e,
            stackTrace: stackTrace,
          );
          return _ErrorView(
            onRetry: () => ref.invalidate(habitsNotifierProvider),
          );
        },
        data: (list) {
          if (list.isEmpty) return _EmptyView(onCreate: onCreate);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s4),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
            itemBuilder: (_, i) => _HabitTile(habit: list[i]),
          );
        },
      ),
    );
  }
}

/// D-28 — Vue squelette HA-01 : 5 AppSkeletonCard simulant les habitudes.
class _SkeletonLoadingView extends StatelessWidget {
  const _SkeletonLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s4),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (_, _) => const AppSkeletonCard(lineCount: 3),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  const _HabitTile({required this.habit});

  String _frequencyLabel() {
    switch (habit.frequencyType) {
      case HabitFrequencyType.daily:
        return 'Tous les jours';
      case HabitFrequencyType.perDay:
        return '${habit.frequency}× par jour';
      case HabitFrequencyType.perWeek:
        return '${habit.frequency}× par semaine';
      case HabitFrequencyType.weekly:
        return '${habit.activeDays.length} jour(s) / semaine';
      case HabitFrequencyType.monthly:
        return 'Le ${habit.monthlyDay} de chaque mois';
      case HabitFrequencyType.custom:
        return 'Personnalisée';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: const Icon(
              LucideIcons.target,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name.value,
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  _frequencyLabel(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s2,
              vertical: AppSpacing.s1,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '+${habit.points.value} pts',
              style: AppTypography.label.copyWith(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppLogo(size: 80, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.s4),
          const Text(
            'Aucune habitude pour le moment',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Crée ta première habitude pour démarrer ton suivi quotidien.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(label: 'Nouvelle habitude', onPressed: onCreate),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  /// Callback de relance — invalide le provider pour re-fetcher les données.
  final VoidCallback? onRetry;

  const _ErrorView({this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Message FR neutre (audit TL §B.2 PR #43). Détail loggé caller-side.
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Une erreur est survenue.\nMerci de réessayer plus tard.',
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s4),
              AppButton(
                label: 'Réessayer',
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
