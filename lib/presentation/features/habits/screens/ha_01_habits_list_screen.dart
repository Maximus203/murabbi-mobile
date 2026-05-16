import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_logo.dart';

final _logger = Logger();

/// HA-01 — Liste des habitudes de l'utilisateur (slice 3.D).
///
/// Affichage simple : nom + nombre de points + récurrence textuelle.
/// FAB "Nouvelle habitude" déclenche [onCreate]. Empty state si aucune
/// habitude.
class Ha01HabitsListScreen extends ConsumerWidget {
  final VoidCallback onCreate;
  final VoidCallback onBack;

  const Ha01HabitsListScreen({
    super.key,
    required this.onCreate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: 'Habitudes', onBack: onBack),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreate,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bgSurface,
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Nouvelle habitude'),
      ),
      body: habits.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, stackTrace) {
          // Audit TL §B.2 PR #43 : pas de `e.toString()` brut en UI.
          // Détail loggé via logger.e, libellé canonique FR.
          _logger.e(
            'Ha01HabitsListScreen render error',
            error: e,
            stackTrace: stackTrace,
          );
          return const _ErrorView();
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
                Text(habit.name.value, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  _frequencyLabel(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    // Message FR neutre (audit TL §B.2 PR #43). Détail loggé caller-side.
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Text(
          'Une erreur est survenue.\nMerci de réessayer plus tard.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
