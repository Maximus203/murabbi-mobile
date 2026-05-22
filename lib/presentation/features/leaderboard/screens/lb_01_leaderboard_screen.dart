import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/providers/leaderboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/leader_row.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/podium_col.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// Nombre minimal de participants pour afficher un classement (sinon empty
/// state). TODO(Q-leaderboard-min) à valider PO — défaut raisonnable : 3.
const int _kMinParticipants = 3;

/// LB-01 — Classement hebdomadaire (issue #6, Phase 5).
///
/// Podium top 3, liste des rangs suivants, mise en évidence du rang de
/// l'utilisateur connecté, empty state si pas assez de participants.
class Lb01LeaderboardScreen extends ConsumerWidget {
  const Lb01LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: leaderboard.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: AppBorderWidth.indicatorStroke,
            ),
          ),
          error: (e, st) {
            appLog.e('Lb01 leaderboard error', error: e, stackTrace: st);
            return const _LeaderboardError();
          },
          data: (scores) => _LeaderboardBody(
            scores: scores,
            currentUserId: currentUser?.id.value,
          ),
        ),
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  final List<UserScore> scores;
  final String? currentUserId;

  const _LeaderboardBody({required this.scores, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (scores.length < _kMinParticipants) {
      return const _LeaderboardEmpty();
    }

    // Les scores sont déjà triés par rang (vue weekly_leaderboard).
    final podium = scores.take(3).toList();
    final rest = scores.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s8,
      ),
      children: [
        const AppHeader.title(title: 'Classement'),
        const SizedBox(height: AppSpacing.s3),
        Text(
          'Cette semaine',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s5),
        _Podium(podium: podium),
        const SizedBox(height: AppSpacing.s6),
        ...rest.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
            child: LeaderRow(
              score: s,
              initials: _initials(s.userId.value),
              isCurrentUser: s.userId.value == currentUserId,
            ),
          ),
        ),
      ],
    );
  }
}

/// Podium top 3 — ordre visuel 2-1-3 (le 1er au centre, surélevé).
class _Podium extends StatelessWidget {
  final List<UserScore> podium;
  const _Podium({required this.podium});

  @override
  Widget build(BuildContext context) {
    // podium est trié par rang : [1er, 2e, 3e]. Ordre d'affichage : 2-1-3.
    final ordered = <UserScore>[
      if (podium.length > 1) podium[1],
      podium[0],
      if (podium.length > 2) podium[2],
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final s in ordered) ...[
          PodiumCol(score: s, initials: _initials(s.userId.value)),
          const SizedBox(width: AppSpacing.s4),
        ],
      ],
    );
  }
}

/// Initiales d'affichage dérivées de l'identifiant utilisateur.
///
/// TODO(Q-leaderboard-pseudo) à valider PO — la vue `weekly_leaderboard`
/// n'expose pas le pseudo ; on dérive 2 caractères de l'`user_id`. À
/// remplacer par les vraies initiales du pseudo quand la vue les exposera.
String _initials(String userId) {
  final cleaned = userId.replaceAll('-', '');
  if (cleaned.length < 2) return cleaned.toUpperCase().padRight(2, '·');
  return cleaned.substring(0, 2).toUpperCase();
}

class _LeaderboardEmpty extends StatelessWidget {
  const _LeaderboardEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              lu(LucideIcons.trophy),
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.s4),
            const Text('Classement à venir', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Pas encore assez de participants cette semaine. '
              'Continue tes habitudes pour apparaître ici.',
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

class _LeaderboardError extends StatelessWidget {
  const _LeaderboardError();

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
