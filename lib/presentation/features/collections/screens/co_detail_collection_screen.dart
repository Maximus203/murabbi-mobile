import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_badge.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// CO-DETAIL — Détail d'une collection (issue #6, Phase 5).
///
/// Affiche la description, la liste des habitudes (nombre), le potentiel
/// journalier et un bouton Activer (collections système non encore actives).
///
/// Accepte soit [collection] directement (tests, navigation avec `extra`),
/// soit [collectionId] (navigation par path param go_router).
class CoDetailCollectionScreen extends ConsumerWidget {
  /// Entité passée directement — prioritaire sur [collectionId].
  final Collection? collection;

  /// Identifiant string passé via le path param go_router — ignoré si
  /// [collection] est fourni.
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

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: isLoading && match == null
            ? const Center(child: CircularProgressIndicator())
            : match == null
                ? _Missing(onBack: onBack)
                : _DetailBody(collection: match, onBack: onBack),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Collection collection;
  final VoidCallback onBack;

  const _DetailBody({required this.collection, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitCount = collection.habitIds.length;
    final isActivating = ref.watch(collectionsNotifierProvider).isLoading;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        AppHeader.back(title: collection.name.value, onBack: onBack),
        const SizedBox(height: AppSpacing.s4),
        if (collection.isSystem) ...[
          const AppBadge(label: 'Système'),
          const SizedBox(height: AppSpacing.s4),
        ],
        Text(collection.description.value, style: AppTypography.body),
        const SizedBox(height: AppSpacing.s5),
        AppCard(
          child: Row(
            children: [
              Icon(
                lu(LucideIcons.listChecks),
                size: 20,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  '$habitCount habitude${habitCount > 1 ? "s" : ""} '
                  'dans cette collection',
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        if (collection.isActive)
          AppCard(
            child: Row(
              children: [
                Icon(
                  lu(LucideIcons.circleCheck),
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  'Collection active',
                  style: AppTypography.body.copyWith(color: AppColors.success),
                ),
              ],
            ),
          )
        else
          AppButton(
            label: 'Activer la collection',
            onPressed: isActivating
                ? null
                : () => ref
                      .read(collectionsNotifierProvider.notifier)
                      .activate(collection.id),
          ),
      ],
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
