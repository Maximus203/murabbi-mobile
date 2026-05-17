import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/providers/leaderboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// LB-01 — Classement hebdomadaire (top 50).
///
/// Affiche les [UserScore] triés par rang hebdomadaire.
/// La ligne de l'utilisateur courant est mise en évidence.
/// Pull-to-refresh via [RefreshIndicator].
class Lb01LeaderboardScreen extends ConsumerWidget {
  const Lb01LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const AppHeader.title(title: 'Classement'),
      body: leaderboard.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, stackTrace) {
          appLog.e(
            'Lb01LeaderboardScreen render error',
            error: e,
            stackTrace: stackTrace,
          );
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Erreur de chargement',
                  style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.s4),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw),
                  onPressed: () =>
                      ref.read(leaderboardNotifierProvider.notifier).refresh(),
                ),
              ],
            ),
          );
        },
        data: (scores) {
          if (scores.isEmpty) {
            return Center(
              child: Text(
                'Aucun score disponible',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(leaderboardNotifierProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s4),
              itemCount: scores.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.s3),
              itemBuilder: (_, i) => _ScoreTile(
                score: scores[i],
                isCurrentUser:
                    currentUser != null && scores[i].userId == currentUser.id,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sous-widgets privés
// ---------------------------------------------------------------------------

class _ScoreTile extends StatelessWidget {
  final UserScore score;
  final bool isCurrentUser;

  const _ScoreTile({required this.score, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final rank = score.weeklyRank;
    final isTop3 = rank <= 3;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          // Rang
          SizedBox(
            width: 36,
            child: Text(
              '#$rank',
              style: (isTop3
                      ? AppTypography.h2
                      : AppTypography.body)
                  .copyWith(
                color: isTop3 ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          // Avatar niveau
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Center(
              child: Text(
                _levelEmoji(score.currentLevel),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          // Identifiant anonymisé (userId tronqué V1 — pseudo sera ajouté V2)
          Expanded(
            child: Text(
              isCurrentUser
                  ? 'Toi'
                  : 'Utilisateur ${score.userId.value.substring(0, 6)}…',
              style: AppTypography.body.copyWith(
                color: isCurrentUser
                    ? AppColors.accent
                    : AppColors.textPrimary,
                fontWeight:
                    isCurrentUser ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          // Points hebdo
          Text(
            '${score.weeklyPoints} pts',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _levelEmoji(Level level) {
    return switch (level) {
      Level.aspirant => '🌱',
      Level.murid => '📖',
      Level.salik => '⭐',
      Level.mujahid => '🔥',
      Level.wali => '💎',
      Level.murabbi => '👑',
    };
  }
}
