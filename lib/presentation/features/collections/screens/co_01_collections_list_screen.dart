import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/widgets/collection_card.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// CO-01 — Liste des collections d'habitudes (issue #6, Phase 5).
///
/// Sépare collections actives, suggestions système et collections utilisateur
/// inactives. Empty state si aucune collection. Tap sur une carte → CO-DETAIL ;
/// bouton "+" dans le header → CO-02.
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
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: collections.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: AppBorderWidth.indicatorStroke,
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
          ),
        ),
      ),
    );
  }
}

class _CollectionsBody extends ConsumerWidget {
  final List<Collection> collections;
  final void Function(String) onOpenCollection;
  final List<Habit>? habits;

  const _CollectionsBody({
    required this.collections,
    required this.onOpenCollection,
    this.habits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = collections.where((c) => c.isActive).toList();
    final systemSuggestions = collections
        .where((c) => c.isSystem && !c.isActive)
        .toList();
    final userInactive = collections
        .where((c) => !c.isSystem && !c.isActive)
        .toList();

    if (collections.isEmpty) {
      return const _CollectionsFullEmpty();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        // — Collections actives
        if (active.isEmpty)
          const _EmptyActiveHeader()
        else ...[
          const _SectionLabel('Mes collections actives'),
          const SizedBox(height: AppSpacing.s3),
          ...active.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: CollectionCard(
                collection: c,
                onTap: () => onOpenCollection(c.id.value),
                ptsPerDay: habits != null ? c.ptsPerDay(habits!) : null,
              ),
            ),
          ),
        ],

        // — Suggestions système (collections système non activées)
        if (systemSuggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s5),
          const _SectionLabel('Collections suggérées'),
          const SizedBox(height: AppSpacing.s3),
          ...systemSuggestions.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: _SuggestionCard(
                collection: c,
                onActivate: () => ref
                    .read(collectionsNotifierProvider.notifier)
                    .activate(CollectionId(c.id.value)),
              ),
            ),
          ),
        ],

        // — Collections utilisateur inactives
        if (userInactive.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s5),
          const _SectionLabel('Mes collections inactives'),
          const SizedBox(height: AppSpacing.s3),
          ...userInactive.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: CollectionCard(
                collection: c,
                onTap: () => onOpenCollection(c.id.value),
                ptsPerDay: habits != null ? c.ptsPerDay(habits!) : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Header affiché dans la liste quand aucune collection n'est encore activée.
class _EmptyActiveHeader extends StatelessWidget {
  const _EmptyActiveHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(lu(LucideIcons.layers), size: 32, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.s3),
          const Text('Aucune collection activée', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Active une collection suggérée ou crée la tienne pour regrouper tes habitudes.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Empty state complet — aucune collection du tout.
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
              size: 48,
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

/// Carte suggestion — collection système non activée.
///
/// Affiche le nom, la description et un bouton "Activer".
class _SuggestionCard extends StatefulWidget {
  final Collection collection;
  final VoidCallback onActivate;

  const _SuggestionCard({required this.collection, required this.onActivate});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _activating = false;

  Future<void> _handleActivate() async {
    if (_activating) return;
    setState(() => _activating = true);
    try {
      widget.onActivate();
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.collection;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de la collection
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(
                  lu(_iconForCollection(c.icon)),
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name.value, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      c.description.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              _TagChip('${c.habitIds.length} habitudes'),
              const SizedBox(width: AppSpacing.s2),
              const _TagChip('Système'),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            label: 'Activer',
            onPressed: _activating ? null : _handleActivate,
            isLoading: _activating,
          ),
        ],
      ),
    );
  }
}

/// Chip label pour les badges de suggestion.
class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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
      text.toUpperCase(),
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

/// Mappe le nom d'icône kebab-case de la collection vers un [LucideIcons].
IconData _iconForCollection(String? iconName) {
  return switch (iconName) {
    'heart' => LucideIcons.heart,
    'brain' => LucideIcons.brain,
    'dumbbell' => LucideIcons.dumbbell,
    'book-open' => LucideIcons.bookOpen,
    'moon' => LucideIcons.moon,
    'sun' => LucideIcons.sun,
    'leaf' => LucideIcons.leaf,
    'zap' => LucideIcons.zap,
    'target' => LucideIcons.target,
    'star' => LucideIcons.star,
    'layers' => LucideIcons.layers,
    _ => LucideIcons.layoutGrid,
  };
}

class _CollectionsError extends StatelessWidget {
  const _CollectionsError();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Text(
          'Une erreur est survenue.\nMerci de réessayer plus tard.',
          textAlign: TextAlign.center,
          style: AppTypography.body,
        ),
      ),
    );
  }
}
