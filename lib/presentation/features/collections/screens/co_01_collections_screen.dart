import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// CO-01 — Liste des collections de l'utilisateur.
///
/// Affiche les collections actives et inactives avec leur statut.
/// Le FAB "Nouvelle collection" déclenche [onCreate].
/// Un tap sur une collection déclenche [onTap].
class Co01CollectionsScreen extends ConsumerWidget {
  final VoidCallback onCreate;
  final void Function(Collection) onTap;

  const Co01CollectionsScreen({
    super.key,
    required this.onCreate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const AppHeader.title(title: 'Collections'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          child: AppButton(label: 'Nouvelle collection', onPressed: onCreate),
        ),
      ),
      body: collections.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, stackTrace) {
          appLog.e(
            'Co01CollectionsScreen render error',
            error: e,
            stackTrace: stackTrace,
          );
          return _ErrorView(
            onRetry: () => ref.invalidate(collectionsNotifierProvider),
          );
        },
        data: (list) {
          if (list.isEmpty) return _EmptyView(onCreate: onCreate);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s4),
            itemCount: list.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.s3),
            itemBuilder: (_, i) =>
                _CollectionTile(collection: list[i], onTap: onTap),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sous-widgets privés
// ---------------------------------------------------------------------------

class _CollectionTile extends StatelessWidget {
  final Collection collection;
  final void Function(Collection) onTap;

  const _CollectionTile({required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(collection),
      child: AppCard(
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
                color: collection.isActive
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.bgInput,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Icon(
                LucideIcons.layoutGrid,
                size: 20,
                color: collection.isActive
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name.value,
                    style: AppTypography.h3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    '${collection.habitIds.length} habitude(s)',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (collection.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Active',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.s2),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.layoutGrid,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Aucune collection',
              style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Crée ta première collection pour regrouper tes habitudes.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s6),
            AppButton(label: 'Nouvelle collection', onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Erreur de chargement',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppButton(label: 'Réessayer', onPressed: onRetry),
        ],
      ),
    );
  }
}
