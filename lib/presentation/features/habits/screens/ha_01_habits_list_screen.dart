import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_chip.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// HA-01 — Liste des habitudes de l'utilisateur (slice 3.D).
///
/// Affichage simple : nom + nombre de points + récurrence textuelle.
/// FAB "Nouvelle habitude" déclenche [onCreate]. Empty state si aucune
/// habitude.
///
/// Issues #77 (empty state icon) + #85 (chips filtres + section header).
class Ha01HabitsListScreen extends ConsumerStatefulWidget {
  final VoidCallback onCreate;

  /// Ouvre l'écran de gestion des catégories HB-03 (issue #150).
  /// Optionnel — si `null`, le bouton catégories n'est pas affiché.
  final VoidCallback? onOpenCategories;

  const Ha01HabitsListScreen({
    super.key,
    required this.onCreate,
    this.onOpenCategories,
  });

  @override
  ConsumerState<Ha01HabitsListScreen> createState() =>
      _Ha01HabitsListScreenState();
}

class _Ha01HabitsListScreenState extends ConsumerState<Ha01HabitsListScreen> {
  /// Filtre catégorie actif — null signifie "Toutes".
  CategoryId? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.title(
        title: 'Habitudes',
        trailing: widget.onOpenCategories == null
            ? null
            : IconButton(
                tooltip: 'Catégories',
                splashRadius: 18,
                onPressed: widget.onOpenCategories,
                icon: const Icon(
                  LucideIcons.tags,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: AppButton(
            label: 'Nouvelle habitude',
            onPressed: widget.onCreate,
          ),
        ),
      ),
      body: habits.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidth.indicatorStroke,
          ),
        ),
        error: (e, stackTrace) {
          // Audit TL §B.2 PR #43 : pas de `e.toString()` brut en UI.
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
          if (list.isEmpty) return _EmptyView(onCreate: widget.onCreate);

          // Filtrage local par catégorie sélectionnée.
          final filtered = _selectedCategoryId == null
              ? list
              : list.where((h) => h.categoryId == _selectedCategoryId).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Chips filtres catégorie ─────────────────────────────
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (categories) => _CategoryChipsBar(
                  categories: categories,
                  selectedId: _selectedCategoryId,
                  onSelected: (id) => setState(() => _selectedCategoryId = id),
                ),
              ),

              // ── Compteur discret ────────────────────────────────────
              if (filtered.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s4,
                    AppSpacing.s3,
                    AppSpacing.s4,
                    0,
                  ),
                  child: Text(
                    '${filtered.length} habitude${filtered.length > 1 ? "s" : ""}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

              // ── Liste ───────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune habitude dans cette catégorie.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.s4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s3),
                        itemBuilder: (_, i) => _HabitTile(habit: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Barre horizontale scrollable de chips de filtre par catégorie.
///
/// Issue #85 — filtre local, state dans [_Ha01HabitsListScreenState].
class _CategoryChipsBar extends StatelessWidget {
  final List<Category> categories;
  final CategoryId? selectedId;
  final ValueChanged<CategoryId?> onSelected;

  const _CategoryChipsBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s2,
        ),
        children: [
          // Chip "Toutes" — sélectionné quand selectedId == null.
          AppChip(
            label: 'Toutes',
            selected: selectedId == null,
            onTap: () => onSelected(null),
          ),
          for (final cat in categories) ...[
            const SizedBox(width: AppSpacing.s2),
            AppChip(
              label: cat.name.value,
              selected: selectedId == cat.id,
              onTap: () => onSelected(cat.id),
              leading: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _hexToColor(cat.color.value),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ],
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

/// Empty state HA-01 — #77 : icône Lucide évocatrice dans un container DS.
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
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: const Icon(
                LucideIcons.clipboardList,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
          ),
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

/// Convertit un token couleur au format `#RRGGBB` (DS — HexColor) en [Color].
Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
