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

/// CO-DETAIL — Détail d'une [Collection].
///
/// Affiche les métadonnées de la collection et permet à l'utilisateur
/// d'activer ou désactiver la collection (bouton toggle).
/// Phase 5 V1 : lecture seule hormis activate/deactivate.
/// Reporté V2 : édition du nom, ajout/retrait d'habitudes.
class CoDetailCollectionScreen extends ConsumerWidget {
  final Collection collection;
  final VoidCallback onBack;

  const CoDetailCollectionScreen({
    super.key,
    required this.collection,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On relit le notifier pour obtenir la version fraîche (post-activate).
    final collectionsAsync = ref.watch(collectionsNotifierProvider);

    // Résout la collection courante depuis le state si disponible.
    final current = collectionsAsync.valueOrNull?.firstWhere(
      (c) => c.id == collection.id,
      orElse: () => collection,
    ) ?? collection;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: current.name.value,
        onBack: onBack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          // --- Carte infos ---
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: current.isActive
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.bgInput,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Icon(
                        LucideIcons.layoutGrid,
                        size: 22,
                        color: current.isActive
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(current.name.value, style: AppTypography.h2),
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            current.isSystem
                                ? 'Collection système'
                                : 'Collection personnelle',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(current.description.value, style: AppTypography.body),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  '${current.habitIds.length} habitude(s)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),

          // --- Bouton toggle ---
          if (current.isActive)
            AppButton(
              key: const Key('btn_deactivate'),
              label: 'Désactiver la collection',
              variant: AppButtonVariant.secondary,
              onPressed: () => _toggle(ref, current, activate: false),
            )
          else
            AppButton(
              key: const Key('btn_activate'),
              label: 'Activer la collection',
              onPressed: () => _toggle(ref, current, activate: true),
            ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    WidgetRef ref,
    Collection c, {
    required bool activate,
  }) async {
    try {
      if (activate) {
        await ref
            .read(collectionsNotifierProvider.notifier)
            .activate(c.id);
      } else {
        await ref
            .read(collectionsNotifierProvider.notifier)
            .deactivate(c.id);
      }
    } catch (e, st) {
      appLog.e('CoDetailCollectionScreen toggle error', error: e, stackTrace: st);
    }
  }
}
