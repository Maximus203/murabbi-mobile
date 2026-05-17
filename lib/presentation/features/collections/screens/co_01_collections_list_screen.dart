import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/widgets/collection_card.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// CO-01 — Liste des collections d'habitudes (issue #6, Phase 5).
///
/// Sépare collections système et collections utilisateur. Empty state si
/// aucune collection. Tap sur une carte → CO-DETAIL ; FAB → CO-02.
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
      floatingActionButton: FloatingActionButton(
        onPressed: onCreate,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bgSurface,
        child: Icon(lu(LucideIcons.plus)),
      ),
      body: SafeArea(
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
          ),
        ),
      ),
    );
  }
}

class _CollectionsBody extends StatelessWidget {
  final List<Collection> collections;
  final void Function(String) onOpenCollection;

  const _CollectionsBody({
    required this.collections,
    required this.onOpenCollection,
  });

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return const _CollectionsEmpty();
    }

    final system = collections.where((c) => c.isSystem).toList();
    final user = collections.where((c) => !c.isSystem).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        const AppHeader.title(title: 'Collections'),
        const SizedBox(height: AppSpacing.s4),
        if (system.isNotEmpty) ...[
          const _SectionLabel('Collections système'),
          const SizedBox(height: AppSpacing.s3),
          ...system.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: CollectionCard(
                collection: c,
                onTap: () => onOpenCollection(c.id.value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
        if (user.isNotEmpty) ...[
          const _SectionLabel('Mes collections'),
          const SizedBox(height: AppSpacing.s3),
          ...user.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: CollectionCard(
                collection: c,
                onTap: () => onOpenCollection(c.id.value),
              ),
            ),
          ),
        ],
      ],
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

class _CollectionsEmpty extends StatelessWidget {
  const _CollectionsEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.folderOpen,
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
