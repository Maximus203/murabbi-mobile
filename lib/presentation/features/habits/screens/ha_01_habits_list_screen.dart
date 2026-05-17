import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/category_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_chip.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';

/// Filtres disponibles pour la liste des habitudes.
enum _HabitFilter { all, today, todo }

/// HA-01 — Liste des habitudes de l'utilisateur (spec v1.5 slice 3.D).
///
/// Affiche les habitudes regroupées par catégorie, avec filter chips,
/// section headers et habit rows v1.5. Le bouton "+" est dans le header.
/// Empty state SVG si aucune habitude.
class Ha01HabitsListScreen extends ConsumerStatefulWidget {
  final VoidCallback onCreate;

  const Ha01HabitsListScreen({super.key, required this.onCreate});

  @override
  ConsumerState<Ha01HabitsListScreen> createState() =>
      _Ha01HabitsListScreenState();
}

class _Ha01HabitsListScreenState extends ConsumerState<Ha01HabitsListScreen> {
  _HabitFilter _activeFilter = _HabitFilter.all;

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.title(
        title: 'Mes Habitudes',
        trailing: IconButton(
          onPressed: widget.onCreate,
          icon: const Icon(LucideIcons.plus, size: 22, color: AppColors.accent),
          tooltip: 'Nouvelle habitude',
        ),
      ),
      body: Column(
        children: [
          _FilterChipBar(
            active: _activeFilter,
            onChanged: (f) => setState(() => _activeFilter = f),
          ),
          Expanded(
            child: habits.when(
              loading: () => const _SkeletonLoadingView(),
              error: (e, stackTrace) {
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
                if (list.isEmpty) {
                  return _EmptyHabitsState(onCreate: widget.onCreate);
                }
                return categoriesAsync.when(
                  loading: () => const _SkeletonLoadingView(),
                  error: (Object e, StackTrace st) => _HabitListView(
                    habits: _applyFilter(list),
                    categories: const [],
                    onCreate: widget.onCreate,
                  ),
                  data: (cats) => _HabitListView(
                    habits: _applyFilter(list),
                    categories: cats,
                    onCreate: widget.onCreate,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Habit> _applyFilter(List<Habit> all) {
    switch (_activeFilter) {
      case _HabitFilter.all:
        return all;
      case _HabitFilter.today:
        // Filtre : habitudes actives aujourd'hui (weekday Dart : 1=lun..7=dim)
        final todayWeekday = DateTime.now().weekday;
        return all
            .where(
              (h) =>
                  h.frequencyType == HabitFrequencyType.daily ||
                  h.activeDays.contains(todayWeekday),
            )
            .toList();
      case _HabitFilter.todo:
        // V1 : "à faire" = même filtre que "aujourd'hui" (statut non persisté)
        final todayWeekday = DateTime.now().weekday;
        return all
            .where(
              (h) =>
                  h.frequencyType == HabitFrequencyType.daily ||
                  h.activeDays.contains(todayWeekday),
            )
            .toList();
    }
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChipBar extends StatelessWidget {
  final _HabitFilter active;
  final ValueChanged<_HabitFilter> onChanged;

  const _FilterChipBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            AppChip(
              label: 'Toutes',
              selected: active == _HabitFilter.all,
              onTap: () => onChanged(_HabitFilter.all),
            ),
            const SizedBox(width: AppSpacing.s2),
            AppChip(
              label: "Aujourd'hui",
              selected: active == _HabitFilter.today,
              onTap: () => onChanged(_HabitFilter.today),
            ),
            const SizedBox(width: AppSpacing.s2),
            AppChip(
              label: 'À faire',
              selected: active == _HabitFilter.todo,
              onTap: () => onChanged(_HabitFilter.todo),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Habit list grouped by category ───────────────────────────────────────────

class _HabitListView extends StatelessWidget {
  final List<Habit> habits;
  final List<Category> categories;
  final VoidCallback onCreate;

  const _HabitListView({
    required this.habits,
    required this.categories,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) return _EmptyHabitsState(onCreate: onCreate);

    // Grouper par catégorie
    final Map<String, List<Habit>> grouped = {};
    for (final h in habits) {
      grouped.putIfAbsent(h.categoryId.value, () => []).add(h);
    }

    final categoryMap = {for (final c in categories) c.id.value: c};

    final sections = <Widget>[];
    grouped.forEach((catId, catHabits) {
      final cat = categoryMap[catId];
      sections.add(
        _CategorySectionHeader(
          name: cat?.name.value ?? catId,
          color: cat != null ? _hexToColor(cat.color.value) : AppColors.accent,
          done: 0,
          total: catHabits.length,
        ),
      );
      for (final h in catHabits) {
        sections.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s1,
            ),
            child: _HabitRowV15(
              habit: h,
              categoryColor: cat != null
                  ? _hexToColor(cat.color.value)
                  : AppColors.accent,
              // Issue #125 : icône dérivée de la catégorie de l'habitude
              // (slug en base) — plus de `target` uniforme.
              categoryIcon: categoryIconFromSlug(cat?.icon),
            ),
          ),
        );
      }
      sections.add(const SizedBox(height: AppSpacing.s3));
    });

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s6),
      children: sections,
    );
  }
}

// ── Category section header ───────────────────────────────────────────────────

class _CategorySectionHeader extends StatelessWidget {
  final String name;
  final Color color;
  final int done;
  final int total;

  const _CategorySectionHeader({
    required this.name,
    required this.color,
    required this.done,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Text(
              name.toUpperCase(),
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Text(
            '$done / $total',
            style: AppTypography.caption.copyWith(
              fontFamily: 'Geist Mono',
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Habit row v1.5 ────────────────────────────────────────────────────────────

class _HabitRowV15 extends StatefulWidget {
  final Habit habit;
  final Color categoryColor;

  /// Icône dérivée de la catégorie (issue #125).
  final IconData categoryIcon;

  const _HabitRowV15({
    required this.habit,
    required this.categoryColor,
    required this.categoryIcon,
  });

  @override
  State<_HabitRowV15> createState() => _HabitRowV15State();
}

class _HabitRowV15State extends State<_HabitRowV15> {
  bool _checked = false;

  String _frequencyLabel() {
    switch (widget.habit.frequencyType) {
      case HabitFrequencyType.daily:
        return 'Tous les jours';
      case HabitFrequencyType.perDay:
        return '${widget.habit.frequency}× par jour';
      case HabitFrequencyType.perWeek:
        return '${widget.habit.frequency}× par semaine';
      case HabitFrequencyType.weekly:
        return '${widget.habit.activeDays.length} jour(s) / semaine';
      case HabitFrequencyType.monthly:
        return 'Le ${widget.habit.monthlyDay} de chaque mois';
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
          // Badge icône catégorie (issue #125 — différenciation visuelle)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(
              widget.categoryIcon,
              size: 18,
              color: widget.categoryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),

          // Nom + fréquence + mini progress bar (si target)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.habit.name.value,
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  _frequencyLabel(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.habit.target.hasValue) ...[
                  const SizedBox(height: AppSpacing.s2),
                  _MiniProgressBar(color: widget.categoryColor),
                ],
              ],
            ),
          ),

          // Timer badge si actif
          if (widget.habit.target is HabitTargetTimed) ...[
            const SizedBox(width: AppSpacing.s2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: AppSpacing.s1,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.timer,
                    size: 10,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.s1),
                  Text(
                    '${(widget.habit.target as HabitTargetTimed).value.value} min',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(width: AppSpacing.s3),

          // Bouton check à droite
          GestureDetector(
            onTap: () => setState(() => _checked = !_checked),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _checked
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.bgInput,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(
                  color: _checked
                      ? AppColors.success
                      : AppColors.borderEmphasis,
                  width: AppBorderWidth.thin,
                ),
              ),
              child: Icon(
                _checked ? LucideIcons.check : LucideIcons.check,
                size: 16,
                color: _checked ? AppColors.success : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini progress bar ─────────────────────────────────────────────────────────

class _MiniProgressBar extends StatelessWidget {
  final Color color;

  const _MiniProgressBar({required this.color});

  @override
  Widget build(BuildContext context) {
    // V1 : valeur placeholder 0.0 (statut non persisté)
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: 0,
        minHeight: 4,
        backgroundColor: AppColors.bgInput,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

// ── Empty state SVG ───────────────────────────────────────────────────────────

/// Empty state HA-01 avec illustration SVG, message et CTA.
class _EmptyHabitsState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyHabitsState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvgPicture.asset(
            'assets/svg/illo_empty_habits.svg',
            width: 160,
            height: 160,
          ),
          const SizedBox(height: AppSpacing.s6),
          const Text(
            'Aucune habitude configurée',
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
          AppButton(label: 'Ajouter une habitude', onPressed: onCreate),
        ],
      ),
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────────

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

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback? onRetry;

  const _ErrorView({this.onRetry});

  @override
  Widget build(BuildContext context) {
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

/// Convertit un token couleur `#RRGGBB` en [Color].
Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
