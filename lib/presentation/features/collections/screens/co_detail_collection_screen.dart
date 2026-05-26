import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// CO-DETAIL — Détail d'une collection (issue #6, Phase 5).
///
/// Affiche la catégorie, la description, la liste des habitudes incluses et
/// le potentiel journalier. Footer sticky : pts/jour + bouton
/// Activer / Désactiver.
///
/// Menu "..." (Q-collections-01 — Option A) : visible uniquement pour les
/// collections utilisateur (`!isSystem`) → supprime la collection.
///
/// Accepte [collection] directement (tests / navigation avec `extra`) ou
/// [collectionId] (path param go_router).
class CoDetailCollectionScreen extends ConsumerWidget {
  /// Entité passée directement — prioritaire sur [collectionId].
  final Collection? collection;

  /// Identifiant string passé via le path param go_router.
  final String? collectionId;

  final VoidCallback onBack;

  const CoDetailCollectionScreen({
    super.key,
    this.collection,
    this.collectionId,
    required this.onBack,
  }) : assert(
         collection != null || collectionId != null,
         'Fournir collection ou collectionId',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Collection? match;
    bool isLoading = false;

    if (collection != null) {
      match = collection;
    } else {
      final collectionsAsync = ref.watch(collectionsNotifierProvider);
      isLoading = collectionsAsync.isLoading;
      final found = collectionsAsync.valueOrNull
          ?.where((c) => c.id.value == collectionId)
          .toList();
      match = (found == null || found.isEmpty) ? null : found.first;
    }

    // Habits et catégories partagés avec le reste de l'app (cache Riverpod).
    final allHabits = ref.watch(habitsNotifierProvider).valueOrNull ?? [];
    final allCategories =
        ref.watch(categoriesNotifierProvider).valueOrNull ?? [];

    final categoryMap = <CategoryId, Category>{
      for (final c in allCategories) c.id: c,
    };

    if (isLoading && match == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (match == null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: _Missing(onBack: onBack),
      );
    }

    return _DetailScaffold(
      collection: match,
      allHabits: allHabits,
      categoryMap: categoryMap,
      onBack: onBack,
    );
  }
}

class _DetailScaffold extends ConsumerWidget {
  final Collection collection;
  final List<Habit> allHabits;
  final Map<CategoryId, Category> categoryMap;
  final VoidCallback onBack;

  const _DetailScaffold({
    required this.collection,
    required this.allHabits,
    required this.categoryMap,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActivating = ref.watch(collectionsNotifierProvider).isLoading;

    // Habitudes de cette collection.
    final habitIdSet = collection.habitIds.map((h) => h.value).toSet();
    final collectionHabits = allHabits
        .where((h) => habitIdSet.contains(h.id.value))
        .toList();

    // Catégorie principale de la collection (pour le sous-titre).
    final primaryCategory = collection.primaryCategoryId != null
        ? categoryMap[collection.primaryCategoryId]
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: collection.name.value,
        onBack: onBack,
        // Menu "..." uniquement pour les collections utilisateur (Q-collections-01).
        trailing: !collection.isSystem
            ? IconButton(
                key: const Key('btn_delete_menu'),
                onPressed: () => _showDeleteDialog(context, ref),
                splashRadius: 18,
                icon: Icon(
                  lu(LucideIcons.ellipsis),
                  size: AppIconSize.rg,
                  color: AppColors.textPrimary,
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s4,
            AppSpacing.s5,
            AppSpacing.s4,
          ),
          children: [
            // Sous-titre catégorie + Système.
            if (primaryCategory != null || collection.isSystem)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: _CategorySubtitle(
                  category: primaryCategory,
                  isSystem: collection.isSystem,
                ),
              ),

            // Description.
            Text(collection.description.value, style: AppTypography.body),
            const SizedBox(height: AppSpacing.s5),

            // Section habitudes.
            Text(
              'HABITUDES INCLUSES',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),

            if (collectionHabits.isEmpty)
              Text(
                'Aucune habitude trouvée dans cette collection.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            else
              ...collectionHabits.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                  child: _HabitRow(habit: h, categoryMap: categoryMap),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _CollectionFooter(
          collection: collection,
          allHabits: allHabits,
          isActivating: isActivating,
          onActivate: () => ref
              .read(collectionsNotifierProvider.notifier)
              .activate(collection.id),
          onDeactivate: () => ref
              .read(collectionsNotifierProvider.notifier)
              .deactivate(collection.id),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext ctx, WidgetRef ref) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('Supprimer la collection', style: AppTypography.h3),
        content: Text(
          'Supprimer "${collection.name.value}" ? Cette action est irréversible.',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Annuler',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref
                  .read(collectionsNotifierProvider.notifier)
                  .delete(collection.id);
              if (ctx.mounted) onBack();
            },
            child: Text(
              'Supprimer',
              style: AppTypography.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sous-titre "● Catégorie · Système" sous le titre de la collection.
class _CategorySubtitle extends StatelessWidget {
  final Category? category;
  final bool isSystem;

  const _CategorySubtitle({this.category, required this.isSystem});

  @override
  Widget build(BuildContext context) {
    final categoryColor = category != null
        ? _colorFromHex(category!.color)
        : AppColors.textTertiary;
    final categoryName = category?.name.value ?? '';

    return Row(
      children: [
        if (category != null) ...[
          Container(
            width: AppComponentSize.dotSize,
            height: AppComponentSize.dotSize,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Text(
            categoryName,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (category != null && isSystem) ...[
          Text(
            ' · ',
            style: AppTypography.body.copyWith(color: AppColors.textTertiary),
          ),
        ],
        if (isSystem)
          Text(
            'Système',
            style: AppTypography.body.copyWith(color: AppColors.textTertiary),
          ),
      ],
    );
  }
}

/// Ligne de détail d'une habitude dans CO-DETAIL.
class _HabitRow extends StatelessWidget {
  final Habit habit;
  final Map<CategoryId, Category> categoryMap;

  const _HabitRow({required this.habit, required this.categoryMap});

  @override
  Widget build(BuildContext context) {
    final category = categoryMap[habit.categoryId];
    final dotColor = category != null
        ? _colorFromHex(category.color)
        : AppColors.accent;

    final freqLabel = _frequencyLabel(habit);
    final durLabel = _durationLabel(habit.target);
    final subtitle = durLabel != null ? '$freqLabel · $durLabel' : freqLabel;
    final pts = habit.points?.value;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          Container(
            width: AppComponentSize.dotSize,
            height: AppComponentSize.dotSize,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name.value,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (pts != null)
            Text(
              '+$pts',
              style: AppTypography.body.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Footer sticky : potentiel journalier + bouton Activer / Désactiver.
class _CollectionFooter extends StatelessWidget {
  final Collection collection;
  final List<Habit> allHabits;
  final bool isActivating;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const _CollectionFooter({
    required this.collection,
    required this.allHabits,
    required this.isActivating,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final pts = collection.ptsPerDay(allHabits);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s5,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderDefault,
            width: AppBorderWidth.thin,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POTENTIEL JOURNALIER',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    '$pts points',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '+$pts',
                style: AppTypography.h2.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          if (collection.isActive)
            AppButton(
              key: const Key('btn_deactivate'),
              label: 'Désactiver la collection',
              variant: AppButtonVariant.secondary,
              onPressed: isActivating ? null : onDeactivate,
              isLoading: isActivating,
            )
          else
            AppButton(
              key: const Key('btn_activate'),
              label: 'Activer cette collection',
              onPressed: isActivating ? null : onActivate,
              isLoading: isActivating,
            ),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  final VoidCallback onBack;
  const _Missing({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader.back(title: 'Collection', onBack: onBack),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s6),
              child: Text('Collection introuvable.', style: AppTypography.body),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Convertit un [HexColor] en [Color] Flutter.
Color _colorFromHex(HexColor hex) {
  final s = hex.value.replaceFirst('#', '');
  return Color(int.parse(s, radix: 16) | 0xFF000000);
}

/// Libellé de fréquence (français) à partir du type et des jours actifs.
String _frequencyLabel(Habit h) {
  return switch (h.frequencyType) {
    HabitFrequencyType.daily => 'Quotidien',
    HabitFrequencyType.perDay => '${h.frequency}×/jour',
    HabitFrequencyType.perWeek => '${h.frequency}×/sem.',
    HabitFrequencyType.weekly => '${h.activeDays.length}j/sem.',
    HabitFrequencyType.monthly => 'Mensuel',
    HabitFrequencyType.custom => 'Personnalisé',
  };
}

/// Libellé de durée si l'habitude a un objectif minuté/horaire.
String? _durationLabel(HabitTarget target) {
  if (target case HabitTargetTimed(value: final v, unit: final u)) {
    return u == TargetUnit.hours ? '${v.value} h' : '${v.value} min';
  }
  return null;
}
