import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_display_item.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/presentation/common/app_video_player.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/daily_summary_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_state.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_ticker_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/niyyah_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/streak_delta_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/user_score_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/widgets/dashboard_score_card.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/widgets/dashboard_stats_grid.dart';
import 'package:murabbi_mobile/presentation/features/gamification/providers/level_up_notifier.dart';
import 'package:murabbi_mobile/presentation/features/gamification/screens/level_up_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/today_habit_statuses_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_media.dart';
import 'package:murabbi_mobile/presentation/theme/app_opacity.dart';
import 'package:murabbi_mobile/presentation/theme/app_responsive.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';
// ignore: prefer_final_fields

/// HM-01 — Écran d'accueil Murabbi (slice 3.A).
///
/// Agrège : salutation, date du jour (grégorienne + hijri), score du jour,
/// intention du jour (niyyah), grille de stats, prochaine prière,
/// et barre de navigation principale.
class Hm01DashboardScreen extends ConsumerWidget {
  final VoidCallback onConfigurePrayers;
  final VoidCallback onOpenSalat;
  final VoidCallback? onSignOut;
  final VoidCallback? onOpenSettings;

  const Hm01DashboardScreen({
    super.key,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
    this.onSignOut,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardNotifierProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    // Issue #168 — affichage canonique `pseudo#XXXX` (fallback `pseudo`
    // brut tant que la migration admin#125 n'a pas projeté pseudo_full).
    final pseudo = user?.displayPseudo ?? 'Murabbi';

    // LEVEL-UP (issue #7) : à chaque nouvelle valeur de score total, on
    // alimente le notifier qui détecte le franchissement d'un palier.
    ref.listen(userScoreProvider, (_, next) {
      final score = next.valueOrNull;
      if (score != null) {
        ref
            .read(levelUpNotifierProvider.notifier)
            .observeTotal(score.totalPoints);
      }
    });
    final pendingLevelUp = ref.watch(levelUpNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: dashboard.when(
              loading: () => const _DashboardSkeleton(),
              error: (e, stackTrace) {
                appLog.e(
                  'Hm01DashboardScreen render error',
                  error: e,
                  stackTrace: stackTrace,
                );
                return const _GenericError();
              },
              data: (data) => _DashboardBody(
                data: data,
                pseudo: pseudo,
                onConfigurePrayers: onConfigurePrayers,
                onOpenSalat: onOpenSalat,
                onSignOut: onSignOut,
                onOpenSettings: onOpenSettings,
              ),
            ),
          ),
          if (pendingLevelUp != null)
            Positioned.fill(
              child: LevelUpScreen(
                levelName: pendingLevelUp.label,
                levelDescription: pendingLevelUp.description,
                onContinue: () =>
                    ref.read(levelUpNotifierProvider.notifier).acknowledge(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  final DashboardState data;
  final String pseudo;
  final VoidCallback onConfigurePrayers;
  final VoidCallback onOpenSalat;
  final VoidCallback? onSignOut;
  final VoidCallback? onOpenSettings;

  const _DashboardBody({
    required this.data,
    required this.pseudo,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
    this.onSignOut,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = data.nowUtc.toLocal();
    final streak =
        ref.watch(authNotifierProvider).valueOrNull?.currentStreak ?? 0;
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        ref.invalidate(dashboardNotifierProvider);
        ref.invalidate(dailySummaryProvider);
        ref.invalidate(niyyahProvider);
        await ref.read(dashboardNotifierProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s6,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        children: [
          // ── En-tête ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASSALAMU ALAYKUM',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(pseudo, style: AppTypography.h1),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      _dualDate(local),
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.bell,
                size: context.rs(AppIconSize.rg),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s3),
              GestureDetector(
                onTap: onOpenSettings,
                child: Semantics(
                  label: 'Ouvrir les paramètres',
                  button: true,
                  child: _UserAvatar(
                    user: ref.watch(authNotifierProvider).valueOrNull,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Score du jour ──────────────────────────────────────────
          _ScoreCard(),
          const SizedBox(height: AppSpacing.s4),

          // ── Habitudes du jour ──────────────────────────────────────
          const _DashboardHabitsSection(),
          const SizedBox(height: AppSpacing.s4),

          // ── Intention du jour (niyyah) ─────────────────────────────
          const _NiyyahCard(),
          const SizedBox(height: AppSpacing.s4),

          // ── Grille de statistiques ─────────────────────────────────
          _StatsCard(
            globalStreak: streak,
            dailyCompletionRate: data.dailyCompletionRate,
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── Prochaine prière ───────────────────────────────────────
          _NextPrayerCard(
            state: data,
            onConfigurePrayers: onConfigurePrayers,
            onOpenSalat: onOpenSalat,
          ),
        ],
      ),
    );
  }

  static const _months = [
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
  static const _weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  static const _hijriMonths = [
    'Muharram',
    'Safar',
    'Rabīʿ al-Awwal',
    'Rabīʿ al-Thānī',
    'Jumādā al-Ūlā',
    'Jumādā al-Ākhira',
    'Rajab',
    'Shaʿbān',
    'Ramadan',
    'Shawwāl',
    'Dhul-Qaʿdah',
    'Dhul-Ḥijjah',
  ];

  /// Retourne la date duale : "Mardi 12 mai 2026 · 14 Dhul-Qaʿdah 1447".
  static String _dualDate(DateTime local) {
    final wd = _weekdays[local.weekday - 1];
    final m = _months[local.month - 1];
    final capitalized = wd[0].toUpperCase() + wd.substring(1);
    final gregorian = '$capitalized ${local.day} $m ${local.year}';

    final hijri = HijriCalendar.fromDate(local);
    final hijriStr =
        '${hijri.hDay} ${_hijriMonths[hijri.hMonth - 1]} ${hijri.hYear}';

    return '$gregorian · $hijriStr';
  }
}

/// Score card isolée — consomme [userScoreProvider] + [dailySummaryProvider].
///
/// Son chargement / erreur ne fait pas vaciller le reste du dashboard.
class _ScoreCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(userScoreProvider);
    final summaryAsync = ref.watch(dailySummaryProvider);

    return scoreAsync.when(
      loading: () => const _ScoreCardSkeleton(),
      error: (e, st) {
        appLog.w('userScoreProvider error', error: e, stackTrace: st);
        return const SizedBox.shrink();
      },
      data: (score) {
        if (score == null) return const SizedBox.shrink();
        final summary = summaryAsync.valueOrNull;
        return DashboardScoreCard(score: score, dailySummary: summary);
      },
    );
  }
}

/// Grille de stats isolée — consomme score, summary, salat, habitudes.
class _StatsCard extends ConsumerWidget {
  final int globalStreak;

  /// Taux de complétion journalier (0.0 à 100.0) depuis `daily_summaries`.
  final double dailyCompletionRate;

  const _StatsCard({
    required this.globalStreak,
    this.dailyCompletionRate = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(userScoreProvider);
    final summaryAsync = ref.watch(dailySummaryProvider);
    final streakDeltaAsync = ref.watch(streakDeltaProvider);

    final salatAsync = ref.watch(todaySalatNotifierProvider);
    final salatLabel =
        salatAsync.whenOrNull(
          data: (s) {
            final statuses = [
              s.prayerDay.fajr,
              s.prayerDay.dhuhr,
              s.prayerDay.asr,
              s.prayerDay.maghrib,
              s.prayerDay.isha,
            ];
            final done = statuses
                .where(
                  (st) =>
                      st != PrayerStatus.pending && st != PrayerStatus.missed,
                )
                .length;
            return '$done/5';
          },
        ) ??
        '—';

    final habitStatuses = ref.watch(todayHabitStatusesProvider);
    final habits = ref.watch(habitsNotifierProvider).valueOrNull ?? const [];
    final completedHabits = habitStatuses.values
        .where((s) => s != HabitLogStatus.missed)
        .length;
    final habitsLabel = habits.isEmpty
        ? '—'
        : '$completedHabits/${habits.length}';

    final score = scoreAsync.valueOrNull;
    final summary = summaryAsync.valueOrNull;

    // Sous-label streak : "+N j" ou "-N j" selon le delta hebdomadaire.
    final streakDelta = streakDeltaAsync.valueOrNull;
    String? streakSubLabel;
    if (streakDelta != null && streakDelta != 0) {
      final sign = streakDelta > 0 ? '+' : '';
      streakSubLabel = '$sign$streakDelta j cette semaine';
    }

    // Sous-label habitudes : "XX% · +N pts" quand summary disponible.
    final habitsSubLabel = summary != null
        ? '${summary.completionRate.round()}% · +${summary.habitPointsToday} pts'
        : null;

    // Sous-label classement : "↗ N places" (haut) ou "↘ N places" (bas).
    String? rankSubLabel;
    if (score != null && score.rankMovement != null) {
      final delta = score.rankMovement!;
      if (delta > 0) {
        rankSubLabel = '↗ $delta place${delta > 1 ? 's' : ''}';
      } else if (delta < 0) {
        rankSubLabel = '↘ ${delta.abs()} place${delta.abs() > 1 ? 's' : ''}';
      }
    }

    return DashboardStatsGrid(
      streakDays: globalStreak,
      salatLabel: salatLabel,
      salatSubLabel: 'à l\'heure',
      habitsLabel: habitsLabel,
      habitsSubLabel: habitsSubLabel,
      weeklyRank: score?.weeklyRank ?? 1,
      streakSubLabel: streakSubLabel,
      rankSubLabel: rankSubLabel,
    );
  }
}

/// Card "Intention du jour" — niyyah personnelle ou suggestion système.
///
/// Fond vidéo local [AppMedia.niyyahLocalVideo] (asset bundlé, 120 px).
/// Dégradé transparent→noir ancré en bas à gauche (DS validé).
/// [AppVideoPlayer] gère le fallback gradient si le player échoue.
class _NiyyahCard extends ConsumerWidget {
  const _NiyyahCard();

  static const String _fallback =
      'Je cherche à plaire à Allah dans tout ce que je fais aujourd\'hui.';
  static const double _height = 160;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final niyyahAsync = ref.watch(niyyahProvider);

    return niyyahAsync.when(
      loading: () => const AppSkeletonCard(lineCount: 2),
      error: (e, _) => _videoCard(text: _fallback, isPersonal: false),
      data: (resolved) => _videoCard(
        text: resolved?.displayText ?? _fallback,
        isPersonal: resolved is UserNiyyah,
      ),
    );
  }

  Widget _videoCard({required String text, required bool isPersonal}) {
    return AppVideoPlayer(
      assetPath: AppMedia.niyyahLocalVideo,
      height: _height,
      borderRadius: BorderRadius.circular(AppRadius.card),
      overlay: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.transparent,
              AppColors.overlayDark.withValues(alpha: AppOpacity.overlayMedium),
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.s4),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'INTENTION DU JOUR',
                  style: AppTypography.label.copyWith(
                    color: AppColors.bgSurface,
                  ),
                ),
                if (isPersonal) ...[
                  const Spacer(),
                  const Icon(
                    LucideIcons.pencil,
                    size: AppIconSize.sm,
                    color: AppColors.videoOverlayText,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '"$text"',
              style: AppTypography.body.copyWith(
                color: AppColors.bgSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton du dashboard complet pendant le chargement initial (UX-1).
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement…',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s6,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        children: const [
          AppSkeletonCard(lineCount: 3), // en-tête
          SizedBox(height: AppSpacing.s4),
          AppSkeletonCard(lineCount: 2), // score card
          SizedBox(height: AppSpacing.s4),
          AppSkeletonCard(lineCount: 2), // niyyah
          SizedBox(height: AppSpacing.s4),
          AppSkeletonCard(lineCount: 2), // stats grid
          SizedBox(height: AppSpacing.s4),
          AppSkeletonCard(lineCount: 3), // prochaine prière
        ],
      ),
    );
  }
}

/// Skeleton sobre pendant le chargement du score.
class _ScoreCardSkeleton extends StatelessWidget {
  const _ScoreCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonCard(lineCount: 2);
  }
}

class _NextPrayerCard extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onConfigurePrayers;
  final VoidCallback onOpenSalat;

  const _NextPrayerCard({
    required this.state,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
  });

  static const Map<String, String> _names = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  @override
  Widget build(BuildContext context) {
    if (state.settingsNotConfigured) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Configurez vos prières', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Indiquez votre position et votre méthode pour afficher les '
              'horaires précis.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(label: 'Configurer', onPressed: onConfigurePrayers),
          ],
        ),
      );
    }

    final next = state.nextPrayer;
    if (next == null) {
      return const AppCard(
        child: Text(
          'Horaires indisponibles pour le moment.',
          style: AppTypography.body,
        ),
      );
    }

    final local = next.timeUtc.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final label = _names[next.name] ?? next.name;

    return Semantics(
      button: true,
      label:
          'Prochaine prière : $label à $hh:$mm. Ouvrir le détail des prières.',
      excludeSemantics: true,
      child: AppCard(
        onTap: onOpenSalat,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.moonStar,
                        size: AppIconSize.md,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        next.isTomorrow
                            ? 'PROCHAINE PRIÈRE (DEMAIN)'
                            : 'PROCHAINE PRIÈRE',
                        style: AppTypography.label.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(label, style: AppTypography.h1),
                      const SizedBox(width: AppSpacing.s3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$hh:$mm',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  _RemainingLabel(
                    initialNow: state.nowUtc,
                    nextUtc: next.timeUtc,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: AppIconSize.md,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sous-widget Consumer qui watch [dashboardTickerProvider] — seul lui
/// rebuild toutes les 30s. Cf. audit TL §B.2 PR #42.
///
/// UX-7 : quand le compte à rebours atteint zéro, invalide
/// [dashboardNotifierProvider] une seule fois (garde `_invalidated`).
class _RemainingLabel extends ConsumerStatefulWidget {
  final DateTime initialNow;
  final DateTime nextUtc;

  const _RemainingLabel({required this.initialNow, required this.nextUtc});

  @override
  ConsumerState<_RemainingLabel> createState() => _RemainingLabelState();
}

class _RemainingLabelState extends ConsumerState<_RemainingLabel> {
  bool _invalidated = false;

  @override
  void didUpdateWidget(_RemainingLabel old) {
    super.didUpdateWidget(old);
    if (old.nextUtc != widget.nextUtc) _invalidated = false;
  }

  @override
  Widget build(BuildContext context) {
    final ticker = ref.watch(dashboardTickerProvider);
    final now = ticker.valueOrNull ?? widget.initialNow;
    final diff = widget.nextUtc.difference(now);
    if (diff.isNegative && !_invalidated) {
      _invalidated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.invalidate(dashboardNotifierProvider);
      });
    }
    return Text(
      'Dans ${_formatRemaining(widget.nextUtc, now)}',
      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
    );
  }

  static String _formatRemaining(DateTime nextUtc, DateTime nowUtc) {
    final diff = nextUtc.difference(nowUtc);
    if (diff.isNegative) return 'maintenant';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours == 0) return '$minutes min';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }
}

/// Avatar circulaire avec l'initiale du pseudo — affiché dans le header HM-01.
class _UserAvatar extends StatelessWidget {
  final User? user;
  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = (user?.pseudo.value ?? '').isEmpty
        ? '?'
        : user!.pseudo.value.characters.first.toUpperCase();
    final size = context.rs(AppComponentSize.avatarSm);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypography.h3.copyWith(color: AppColors.bgSurface),
      ),
    );
  }
}

/// Section mini-habitudes du dashboard HM-01.
///
/// Affiche jusqu'à 6 habitudes du jour avec leur statut (complété, objectif,
/// vide). Un header HABITUDES avec compteur X/Y précède la liste.
/// Si aucune habitude n'est définie, retourne [SizedBox.shrink].
class _DashboardHabitsSection extends ConsumerWidget {
  const _DashboardHabitsSection();

  /// Nombre maximum d'habitudes visibles dans la section dashboard.
  static const int _maxVisible = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsNotifierProvider).valueOrNull ?? const [];
    if (habits.isEmpty) return const SizedBox.shrink();

    final statuses = ref.watch(todayHabitStatusesProvider);
    final categories =
        ref.watch(categoriesNotifierProvider).valueOrNull ?? const [];

    // Index catégories par id pour lookup O(1).
    final categoryMap = <String, Category>{
      for (final c in categories) c.id.value: c,
    };

    final completedCount = statuses.values
        .where((s) => s != HabitLogStatus.missed)
        .length;
    final visible = habits.take(_maxVisible).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'HABITUDES',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount/${habits.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          // ── Liste des habitudes ────────────────────────────────────
          ...visible.map(
            (habit) => _HabitMiniRow(
              habit: habit,
              status: statuses[habit.id],
              category: categoryMap[habit.categoryId.value],
            ),
          ),
          // "et X de plus" si > _maxVisible habitudes
          if (habits.length > _maxVisible) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(
              'et ${habits.length - _maxVisible} de plus…',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ligne compacte d'une habitude dans le dashboard HM-01.
///
/// Dot couleur catégorie · Nom · Statut (check vert si validée, vide sinon).
class _HabitMiniRow extends StatelessWidget {
  final Habit habit;
  final HabitLogStatus? status;
  final Category? category;

  const _HabitMiniRow({
    required this.habit,
    required this.status,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = _resolveColor(category?.color);
    final isDone = status != null && status != HabitLogStatus.missed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: Row(
        children: [
          // Dot couleur catégorie
          Container(
            width: AppComponentSize.dotSize,
            height: AppComponentSize.dotSize,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s2),
          // Nom de l'habitude
          Expanded(
            child: Text(
              habit.name.value,
              style: AppTypography.body.copyWith(
                color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          // Indicateur de statut
          _StatusIndicator(status: status),
        ],
      ),
    );
  }

  /// Résout la couleur du dot depuis le HexColor de la catégorie.
  static Color _resolveColor(HexColor? hexColor) {
    if (hexColor == null) return AppColors.textTertiary;
    try {
      final hex = hexColor.value.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.textTertiary;
    }
  }
}

/// Indicateur de statut compact pour une habitude dans HM-01.
class _StatusIndicator extends StatelessWidget {
  final HabitLogStatus? status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == HabitLogStatus.onTime || status == HabitLogStatus.late) {
      return const Icon(
        LucideIcons.circleCheck,
        size: AppIconSize.sm,
        color: AppColors.success,
      );
    }
    return const SizedBox.shrink();
  }
}

class _GenericError extends ConsumerWidget {
  const _GenericError();

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
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(
              label: 'Réessayer',
              variant: AppButtonVariant.secondary,
              onPressed: () => ref.invalidate(dashboardNotifierProvider),
            ),
          ],
        ),
      ),
    );
  }
}
