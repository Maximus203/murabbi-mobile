import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/providers/leaderboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/leader_row.dart';
import 'package:murabbi_mobile/presentation/features/leaderboard/widgets/podium_col.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';

/// Nombre minimal de participants pour afficher le podium (sinon empty state).
const int _kMinParticipants = 3;

/// LB-01 — Classement hebdomadaire.
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
          loading: () => Semantics(
            label: 'Chargement…',
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              children: const [
                AppSkeletonCard(lineCount: 3),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 2),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 2),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 2),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 2),
              ],
            ),
          ),
          error: (e, st) {
            appLog.e('Lb01 leaderboard error', error: e, stackTrace: st);
            return const _LeaderboardError();
          },
          data: (scores) => _LeaderboardBody(
            scores: scores,
            currentUserId: currentUser?.id.value,
            onRefresh: () async {
              ref.invalidate(leaderboardProvider);
              await ref.read(leaderboardProvider.future);
            },
          ),
        ),
      ),
    );
  }
}

class _LeaderboardBody extends ConsumerWidget {
  final List<UserScore> scores;
  final String? currentUserId;
  final Future<void> Function()? onRefresh;

  const _LeaderboardBody({
    required this.scores,
    required this.currentUserId,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (scores.length < _kMinParticipants) {
      return const _LeaderboardEmpty();
    }

    final now = DateTime.now();
    final weekNumber = _isoWeekNumber(now);
    final dateRange = _weekDateRange(now);
    final participantCount = scores.length;

    // Scores déjà triés par rang (vue weekly_leaderboard ORDER BY rank ASC).
    final podium = scores.take(3).toList();
    final rest = scores.skip(3).toList();

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
          // ── En-tête ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEMAINE $weekNumber',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    const Text('Classement', style: AppTypography.h1),
                  ],
                ),
              ),
              Semantics(
                label: 'Historique des classements',
                button: true,
                child: const Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '$dateRange · $participantCount participant${participantCount > 1 ? "s" : ""}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Podium top 3 ─────────────────────────────────────────────
          _Podium(podium: podium),
          const SizedBox(height: AppSpacing.s6),

          // ── Rangs 4+ ─────────────────────────────────────────────────
          ...rest.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: LeaderRow(
                score: s,
                name: _nameFor(s),
                isCurrentUser: s.userId.value == currentUserId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Podium top 3 — ordre visuel 2-1-3 (1er au centre, surélevé).
class _Podium extends StatelessWidget {
  final List<UserScore> podium;
  const _Podium({required this.podium});

  @override
  Widget build(BuildContext context) {
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
          PodiumCol(score: s, name: _nameFor(s)),
          const SizedBox(width: AppSpacing.s3),
        ],
      ],
    );
  }
}

/// Résout le nom d'affichage — pseudo Supabase si disponible, sinon
/// initiales dérivées de l'userId (défaut défensif).
String _nameFor(UserScore s) {
  final p = s.pseudo;
  if (p != null && p.isNotEmpty) return p;
  final cleaned = s.userId.value.replaceAll('-', '');
  return cleaned.length >= 2
      ? cleaned.substring(0, 2).toUpperCase()
      : cleaned.toUpperCase().padRight(2, '·');
}

/// Numéro de semaine ISO 8601.
int _isoWeekNumber(DateTime date) {
  final jan4 = DateTime(date.year, 1, 4);
  return ((date.difference(jan4).inDays + jan4.weekday) / 7).ceil();
}

/// Plage de dates de la semaine courante : "21 au 27 avril".
String _weekDateRange(DateTime now) {
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  if (monday.month == sunday.month) {
    return '${monday.day} au ${sunday.day} ${months[sunday.month - 1]}';
  }
  return '${monday.day} ${months[monday.month - 1]}'
      ' au ${sunday.day} ${months[sunday.month - 1]}';
}

/// Empty state — affiché si moins de [_kMinParticipants] participants.
class _LeaderboardEmpty extends StatelessWidget {
  const _LeaderboardEmpty();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysUntilSunday = now.weekday == DateTime.sunday
        ? 0
        : 7 - now.weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PodiumIllustration(),
          const SizedBox(height: AppSpacing.s6),
          const Text(
            'Pas encore assez de données',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Le classement sera disponible en fin de semaine, dimanche soir.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s5),
          // Chip avec icône horloge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  daysUntilSunday == 0
                      ? 'Prochain classement ce soir'
                      : 'Prochain classement dans $daysUntilSunday'
                            ' jour${daysUntilSunday > 1 ? "s" : ""}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration podium — 3 barres verticales reproduisant le design EMPTY.
class _PodiumIllustration extends StatelessWidget {
  const _PodiumIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: SizedBox(width: 40, height: 52),
          ),
          SizedBox(width: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: SizedBox(width: 40, height: 72),
          ),
          SizedBox(width: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: SizedBox(width: 40, height: 40),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardError extends ConsumerWidget {
  const _LeaderboardError();

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
              onPressed: () => ref.invalidate(leaderboardProvider),
            ),
          ],
        ),
      ),
    );
  }
}
