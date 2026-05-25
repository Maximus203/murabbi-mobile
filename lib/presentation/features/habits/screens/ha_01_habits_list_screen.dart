import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_filter.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_filter_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/today_habit_statuses_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/widgets/habit_row.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_chip.dart';
import 'package:murabbi_mobile/presentation/widgets/app_filter_chips.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_search_bar.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';

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

  /// Ouvre HA-02 en mode édition pour l'habitude d'identifiant donné
  /// (issue #152). Optionnel — si `null`, l'action "Modifier" est masquée.
  final ValueChanged<String>? onEditHabit;

  /// Ouvre HB-DETAIL pour l'habitude d'identifiant donné (issue #153).
  /// C'est l'action déclenchée par le tap sur la ligne. Optionnel — si
  /// `null`, le tap sur la ligne est inerte.
  final ValueChanged<String>? onOpenHabit;

  /// Navigue vers CO-01 (Collections). Affiché dans l'empty state pour
  /// inviter l'utilisateur à activer une collection pré-configurée.
  final VoidCallback? onOpenCollections;

  const Ha01HabitsListScreen({
    super.key,
    required this.onCreate,
    this.onOpenCategories,
    this.onEditHabit,
    this.onOpenHabit,
    this.onOpenCollections,
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
        title: 'Mes habitudes',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onOpenCategories != null)
              IconButton(
                tooltip: 'Catégories',
                splashRadius: 18,
                onPressed: widget.onOpenCategories,
                icon: const Icon(
                  LucideIcons.tags,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            IconButton(
              tooltip: 'Nouvelle habitude',
              splashRadius: 18,
              onPressed: widget.onCreate,
              icon: const Icon(
                LucideIcons.plus,
                size: 22,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: habits.when(
        loading: () => Semantics(
          label: 'Chargement…',
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            children: const [
              AppSkeletonCard(lineCount: 2),
              SizedBox(height: AppSpacing.s3),
              AppSkeletonCard(lineCount: 2),
              SizedBox(height: AppSpacing.s3),
              AppSkeletonCard(lineCount: 2),
              SizedBox(height: AppSpacing.s3),
              AppSkeletonCard(lineCount: 2),
            ],
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
          if (list.isEmpty) {
            return _EmptyView(
              onCreate: widget.onCreate,
              onOpenCollections: widget.onOpenCollections,
            );
          }

          // Recherche + filtre statut + tri (issue #94) appliqués via le
          // provider dédié — `HabitsNotifier` n'est jamais retouché.
          final searchedSorted = ref.watch(filteredHabitsProvider);

          // Filtrage local additionnel par catégorie sélectionnée (#85).
          final filtered = _selectedCategoryId == null
              ? searchedSorted
              : searchedSorted
                    .where((h) => h.categoryId == _selectedCategoryId)
                    .toList();

          final filter = ref.watch(habitsFilterProvider);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Barre de recherche (issue #94) ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s3,
                  AppSpacing.s4,
                  0,
                ),
                child: AppSearchBar(
                  placeholder: 'Rechercher une habitude',
                  onChanged: (q) =>
                      ref.read(habitsFilterProvider.notifier).setQuery(q),
                ),
              ),

              // ── Chips filtre statut + menu tri (issue #94) ──────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s3,
                  AppSpacing.s4,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppFilterChips(
                        labels: const ['Toutes', 'Actives', 'Inactives'],
                        selectedIndex: filter.status.index,
                        onChanged: (i) => ref
                            .read(habitsFilterProvider.notifier)
                            .setStatus(HabitFilterStatus.values[i]),
                      ),
                    ),
                    _SortMenuButton(
                      current: filter.sortBy,
                      onSelected: (s) =>
                          ref.read(habitsFilterProvider.notifier).setSortBy(s),
                    ),
                  ],
                ),
              ),

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

              // ── Liste groupée par catégorie (issue #94) ─────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune habitude ne correspond.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: () async {
                          ref.invalidate(habitsNotifierProvider);
                          await ref.read(habitsNotifierProvider.future);
                        },
                        child: _SectionedHabitsList(
                          habits: filtered,
                          categories: categoriesAsync.valueOrNull ?? const [],
                          onToggle: _toggle,
                          onOpenHabit: widget.onOpenHabit,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Déclenche le cycle de statut d'une habitude avec feedback d'erreur.
  Future<void> _toggle(HabitId habitId) async {
    try {
      await ref.read(todayHabitStatusesProvider.notifier).toggle(habitId);
    } catch (_) {
      // Le rollback est déjà fait par le notifier — on signale juste l'échec.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de mettre à jour. Réessaie.')),
      );
    }
  }
}

/// Bouton menu de sélection du critère de tri (issue #94).
class _SortMenuButton extends StatelessWidget {
  final HabitSortBy current;
  final ValueChanged<HabitSortBy> onSelected;

  const _SortMenuButton({required this.current, required this.onSelected});

  /// Libellé FR d'un critère de tri.
  static String _label(HabitSortBy s) {
    switch (s) {
      case HabitSortBy.name:
        return 'Nom (A-Z)';
      case HabitSortBy.points:
        return 'Points';
      case HabitSortBy.category:
        return 'Catégorie';
      case HabitSortBy.createdAt:
        return 'Date de création';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<HabitSortBy>(
      tooltip: 'Trier',
      icon: const Icon(
        LucideIcons.arrowUpDown,
        size: 20,
        color: AppColors.textPrimary,
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final s in HabitSortBy.values)
          PopupMenuItem<HabitSortBy>(
            value: s,
            child: Row(
              children: [
                Icon(
                  s == current ? LucideIcons.check : LucideIcons.minus,
                  size: 16,
                  color: s == current
                      ? AppColors.accent
                      : AppColors.transparent,
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(_label(s), style: AppTypography.body),
              ],
            ),
          ),
      ],
    );
  }
}

/// Liste d'habitudes groupée par catégorie avec headers de section (issue #94).
///
/// Chaque section affiche un header `Label` uppercase (nom de catégorie) suivi
/// des habitudes de cette catégorie. L'ordre intra-section est celui issu du
/// tri appliqué par [HabitsFilter].
class _SectionedHabitsList extends StatelessWidget {
  final List<Habit> habits;
  final List<Category> categories;
  final ValueChanged<HabitId> onToggle;
  final ValueChanged<String>? onOpenHabit;

  const _SectionedHabitsList({
    required this.habits,
    required this.categories,
    required this.onToggle,
    required this.onOpenHabit,
  });

  @override
  Widget build(BuildContext context) {
    // Groupement en conservant l'ordre d'apparition des catégories.
    final order = <CategoryId>[];
    final groups = <CategoryId, List<Habit>>{};
    for (final h in habits) {
      if (!groups.containsKey(h.categoryId)) order.add(h.categoryId);
      groups.putIfAbsent(h.categoryId, () => []).add(h);
    }

    final nameById = {for (final c in categories) c.id: c.name.value};

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        for (final catId in order) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.s2,
              bottom: AppSpacing.s2,
            ),
            child: Text(
              (nameById[catId] ?? catId.value).toUpperCase(),
              style: AppTypography.label,
            ),
          ),
          for (final h in groups[catId]!)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: _HabitTile(
                habit: h,
                onToggle: () => onToggle(h.id),
                onOpen: onOpenHabit == null
                    ? null
                    : () => onOpenHabit!(h.id.value),
              ),
            ),
        ],
      ],
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

/// Tuile d'habitude — connecte [HabitRow] au statut du jour (#151).
/// Le tap sur la ligne ouvre HB-DETAIL (#153) ; l'édition se fait depuis
/// le menu "..." de HB-DETAIL.
class _HabitTile extends ConsumerWidget {
  final Habit habit;
  final VoidCallback onToggle;

  /// Ouvre le détail de l'habitude — `null` si la navigation est désactivée.
  final VoidCallback? onOpen;

  const _HabitTile({required this.habit, required this.onToggle, this.onOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(todayHabitStatusesProvider)[habit.id];
    return HabitRow(
      habit: habit,
      todayStatus: status,
      onTap: onOpen ?? () {},
      onToggle: onToggle,
    );
  }
}

/// Empty state HA-01 — icône activité, deux CTAs (wireframe v1.5).
class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;

  /// Navigue vers CO-01 si fourni. Null → bouton masqué.
  final VoidCallback? onOpenCollections;

  const _EmptyView({required this.onCreate, this.onOpenCollections});

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
                LucideIcons.activity,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const Text(
            "Aucune habitude pour l'instant",
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Créez votre première ou activez une collection pré-configurée.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(label: 'Créer une habitude', onPressed: onCreate),
          if (onOpenCollections != null) ...[
            const SizedBox(height: AppSpacing.s3),
            AppButton(
              label: 'Voir les collections',
              variant: AppButtonVariant.secondary,
              onPressed: onOpenCollections,
            ),
          ],
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
