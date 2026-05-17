import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/widgets/category_tile.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// HB-03 — Liste des catégories (système + utilisateur).
///
/// Deux sections : « Catégories système » (non-modifiables, badge cadenas)
/// et « Mes catégories » (modifiables, swipe-to-delete avec confirmation).
/// Empty state si l'utilisateur n'a aucune catégorie personnelle.
class Hb03CategoriesListScreen extends ConsumerWidget {
  /// Ouvre HB-04 en mode création.
  final VoidCallback onCreate;

  /// Ouvre HB-04 en mode édition pour la catégorie [id].
  final void Function(CategoryId id) onEdit;

  const Hb03CategoriesListScreen({
    super.key,
    required this.onCreate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.title(
        title: 'Catégories',
        trailing: IconButton(
          tooltip: 'Nouvelle catégorie',
          splashRadius: 18,
          onPressed: onCreate,
          icon: const Icon(
            LucideIcons.plus,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: categories.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidth.indicatorStroke,
          ),
        ),
        error: (e, stackTrace) {
          appLog.e(
            'Hb03CategoriesListScreen render error',
            error: e,
            stackTrace: stackTrace,
          );
          return _ErrorView(
            onRetry: () => ref.invalidate(categoriesNotifierProvider),
          );
        },
        data: (list) => _CategoriesBody(
          categories: list,
          habitCounts: _habitCounts(ref),
          onCreate: onCreate,
          onEdit: onEdit,
        ),
      ),
    );
  }

  /// Compteur d'habitudes par catégorie — best effort : si les habitudes ne
  /// sont pas chargées, retourne une map vide (compteur masqué).
  Map<CategoryId, int> _habitCounts(WidgetRef ref) {
    final habits = ref.watch(habitsNotifierProvider).valueOrNull;
    if (habits == null) return const {};
    final counts = <CategoryId, int>{};
    for (final h in habits) {
      counts.update(h.categoryId, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

class _CategoriesBody extends ConsumerWidget {
  final List<Category> categories;
  final Map<CategoryId, int> habitCounts;
  final VoidCallback onCreate;
  final void Function(CategoryId id) onEdit;

  const _CategoriesBody({
    required this.categories,
    required this.habitCounts,
    required this.onCreate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final system = categories.where((c) => c.isSystem).toList();
    final mine = categories.where((c) => !c.isSystem).toList();

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () =>
          ref.read(categoriesNotifierProvider.notifier).loadCategories(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          if (system.isNotEmpty) ...[
            const _SectionHeader(label: 'Catégories système'),
            for (final cat in system)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: CategoryTile(
                  name: cat.name.value,
                  color: _hexToColor(cat.color.value),
                  icon: cat.icon,
                  isSystem: true,
                  habitCount: habitCounts[cat.id],
                ),
              ),
            const SizedBox(height: AppSpacing.s4),
          ],
          const _SectionHeader(label: 'Mes catégories'),
          if (mine.isEmpty)
            _EmptyUserCategories(onCreate: onCreate)
          else
            for (final cat in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: Dismissible(
                  key: ValueKey('category-${cat.id.value}'),
                  direction: DismissDirection.endToStart,
                  background: _deleteBackground(),
                  confirmDismiss: (_) => _confirmDelete(context, ref, cat),
                  child: CategoryTile(
                    name: cat.name.value,
                    color: _hexToColor(cat.color.value),
                    icon: cat.icon,
                    habitCount: habitCounts[cat.id],
                    onTap: () => onEdit(cat.id),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 20),
    );
  }

  /// Affiche le dialog de confirmation de suppression. Retourne `true` si
  /// l'utilisateur confirme — la suppression est alors exécutée.
  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Supprimer la catégorie ?',
        body: '« ${category.name.value} » sera définitivement supprimée.',
        confirmLabel: 'Supprimer',
        isDangerous: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
    if (confirmed != true) return false;
    await ref
        .read(categoriesNotifierProvider.notifier)
        .deleteCategory(category.id);
    return true;
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Text(label.toUpperCase(), style: AppTypography.label),
    );
  }
}

/// Empty state de la section « Mes catégories ».
class _EmptyUserCategories extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyUserCategories({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Icon(
              LucideIcons.tags,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const Text(
            'Aucune catégorie personnelle',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Crée une catégorie pour organiser tes habitudes à ta façon.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s5),
          AppButton(label: 'Créer une catégorie', onPressed: onCreate),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

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
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Convertit un token `#RRGGBB` (HexColor) en [Color].
Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
