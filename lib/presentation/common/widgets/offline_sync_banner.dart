import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/services/offline/offline_queue_provider.dart';

/// Bannière affichée en haut de l'écran quand des actions sont en attente
/// de synchronisation réseau (BUG-002).
///
/// Affiche « X action(s) en attente de sync » quand [pendingCount] > 0.
/// Disparaît automatiquement quand la queue est vide.
///
/// Usage :
/// ```dart
/// Stack(
///   children: [
///     // Contenu principal
///     Positioned(
///       top: MediaQuery.of(context).padding.top,
///       left: 0,
///       right: 0,
///       child: OfflineSyncBanner(),
///     ),
///   ],
/// )
/// ```
class OfflineSyncBanner extends ConsumerWidget {
  const OfflineSyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(offlinePendingCountProvider);

    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (Object err, StackTrace st) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Material(
          elevation: 4,
          color: AppColors.warning,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s2,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off,
                    color: AppColors.onOverlay,
                    size: AppIconSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: Text(
                      '$count action${count > 1 ? 's' : ''} en attente de sync',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.onOverlay,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
