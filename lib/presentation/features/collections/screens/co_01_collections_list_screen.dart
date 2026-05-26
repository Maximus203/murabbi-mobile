import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/widgets/collection_card.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_responsive.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';

/// CO-01 — Liste des collections d'habitudes (issue #6, Phase 5).
///
/// Sections :
///   • Carte "Aucune collection activée" si aucune collection active.
///   • "SUGGESTIONS - SYSTÈME" / "SYSTÈME" : toutes les collections système.
///   • "MES COLLECTIONS" : collections créées par l'utilisateur.
///
/// Tap "+" → CO-02 ; tap carte → CO-DETAIL.
class Co01CollectionsListScreen extends ConsumerWidget {
  final void Function(String collectionId) onOpenCollection;
  final VoidCallback onCreate;

  const Co01CollectionsListScreen({
    super.key,
    required this.onOpenCollection,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.title(
        title: 'Collections',
        trailing: IconButton(
          onPressed: onCreate,
          splashRadius: 18,
          icon: Icon(
            lu(LucideIcons.plus),
            size: context.rs(AppIconSize.rg),
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: collections.when(
          loading: () => Semantics(
            label: 'Chargement…',
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s4,
                AppSpacing.s5,
                AppSpacing.s8,
              ),
              children: const [
                AppSkeletonCard(lineCount: 3),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 3),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 3),
              ],
            ),
          ),
          error: (e, st) {
            appLog.e('Co01 list error', error: e, stackTrace: st);
            return const _CollectionsError();
          },
          data: (list) => _CollectionsBody(
            collections: list,
            onOpenCollection: onOpenCollection,
            habits: ref.watch(habitsNotifierProvider).valueOrNull,
            categories:
                ref.watch(categoriesNotifierProvider).valueOrNull ?? [],
            onRefresh: () async {
              ref.invalidate(collectionsNotifierProvider);
              await ref.read(collectionsNotifierProvider.future);
            },
            onActivate: (id) => ref
                .read(collectionsNotifierProvider.notifier)
                .activate(CollectionId(id)),
            isActivating: ref.watch(collectionsNotifierProvider).isLoading,
          ),
        ),
      ),
    );
  }
}

class _CollectionsBody extends StatelessWidget {
  final List<Collection> collections;
  final void Function(String) onOpenCollection;
  final List<Habit>? habits;
  final List<Category> categories;
  final Future<void> Function()? onRefresh;
  final Future<void> Function(String collectionId) onActivate;
  final bool isActivating;

  const _CollectionsBody({
    required this.collections,
    required this.onOpenCollection,
    required this.categories,
    required this.onActivate,
    required this.isActivating,
    this.habits,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Aucune collection (edge case — les collections système sont toujours seedées).
    if (collections.isEmpty) {
      return const _CollectionsFullEmpty();
    }

    // Lookup catégorie par id.
    final categoryMap = <CategoryId, Category>{
      for (final c in categories) c.id: c,
    };

    // Section système : toutes les collections système, actives en premier.
    final systemCollections = collections
        .where((c) => c.isSystem)
        .toList()
      ..sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return 0;
      });

    // Section utilisateur : collections créées par l'utilisateur.
    final userCollections = collections.where((c) => !c.isSystem).toList();

    // Label de section système — "SUGGESTIONS - SYSTÈME" si aucune active.
    final hasActiveSystem = systemCollections.any((c) => c.isActive);
    final systemLabel = hasActiveSystem ? 'SYSTÈME' : 'SUGGESTIONS - SYSTÈME';

    // Carte "Aucune collection activée" si aucune collection active.
    final hasAnyActive = collections.any((c) => c.isActive);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s4,
          AppSpacing.s5,
          AppSpacing.s8,
        ),
        children: [
          // Sous-titre explicatif.
          Text(
            'Activez une collection en un tap. Les habitudes seront ajoutées à votre routine.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s5),

          // Carte "Aucune collection activée".
          if (!hasAnyActive) ...[
            const _EmptyActiveCard(),
            const SizedBox(height: AppSpacing.s5),
          ],

          // Section SYSTÈME.
          if (systemCollections.isNotEmpty) ...[
            _SectionLabel(systemLabel),
            const SizedBox(height: AppSpacing.s3),
            ...systemCollections.map((c) {
              final cat = c.primaryCategoryId != null
                  ? categoryMap[c.primaryCategoryId]
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: CollectionCard(
                  collection: c,
                  onTap: () => onOpenCollection(c.id.value),
                  categoryName: cat?.name.value,
                  categoryColor: cat != null ? _colorFromHex(cat.color) : null,
                  ptsPerDay: habits != null ? c.ptsPerDay(habits!) : null,
                  onActivate: c.isActive
                      ? null
                      : () => onActivate(c.id.value),
                  isActivating: isActivating,
                ),
              );
            }),
          ],

          // Section MES COLLECTIONS.
          if (userCollections.isNotEmpty) ...[
            if (systemCollections.isNotEmpty)
              const SizedBox(height: AppSpacing.s5),
            const _SectionLabel('MES COLLECTIONS'),
            const SizedBox(height: AppSpacing.s3),
            ...userCollections.map((c) {
              final cat = c.primaryCategoryId != null
                  ? categoryMap[c.primaryCategoryId]
                  : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                child: CollectionCard(
                  collection: c,
                  onTap: () => onOpenCollection(c.id.value),
                  categoryName: cat?.name.value,
                  categoryColor: cat != null ? _colorFromHex(cat.color) : null,
                  ptsPerDay: habits != null ? c.ptsPerDay(habits!) : null,
                  // Les collections utilisateur s'activent depuis CO-DETAIL.
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Carte centrée "Aucune collection activée" — design EMPTY state.
class _EmptyActiveCard extends StatelessWidget {
  const _EmptyActiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s6),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppComponentSize.iconSelectorCell,
            height: AppComponentSize.iconSelectorCell,
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(
              lu(LucideIcons.layers),
              size: AppIconSize.rg,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          const Text('Aucune collection activée', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Activez une collection système ou créez la vôtre pour structurer votre pratique.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Empty state complet — aucune collection en base (edge case).
class _CollectionsFullEmpty extends StatelessWidget {
  const _CollectionsFullEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              lu(LucideIcons.folderOpen),
              size: AppIconSize.xxl,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.s4),
            const Text('Aucune collection', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Crée ta première collection pour regrouper tes habitudes.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _CollectionsError extends ConsumerWidget {
  const _CollectionsError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Une erreur est survenue.\nMerci de réessayer plus tard.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.secondary,
              onPressed: () => ref.invalidate(collectionsNotifierProvider),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convertit un [HexColor] (`#RRGGBB`) en [Color] Flutter.
Color _colorFromHex(HexColor hex) {
  final s = hex.value.replaceFirst('#', '');
  return Color(int.parse(s, radix: 16) | 0xFF000000);
}
