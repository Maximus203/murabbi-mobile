import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_state.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_ticker_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/user_score_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/widgets/dashboard_score_card.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/widgets/dashboard_stats_grid.dart';
import 'package:murabbi_mobile/presentation/features/gamification/providers/level_up_notifier.dart';
import 'package:murabbi_mobile/presentation/features/gamification/screens/level_up_screen.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/today_habit_statuses_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';

// ignore: prefer_final_fields

/// HM-01 — Écran d'accueil Murabbi (slice 3.A).
///
/// Agrège : salutation, date du jour (grégorienne + hijri), prochaine prière,
/// placeholders habitudes / niyyah / streak (slices à venir 3.D/3.E/scoring),
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
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: AppBorderWidth.indicatorStroke,
                ),
              ),
              error: (e, stackTrace) {
                // Audit TL §B.2 PR #42 : pas de `e.toString()` brut exposé.
                // Détail loggé via appLog, libellé canonique FR.
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
          // Overlay plein écran LEVEL-UP — affiché tant qu'un palier vient
          // d'être franchi ; "Continuer" appelle `acknowledge`.
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // D-30 : salutation en body/accent — plus visible
                    Text(
                      'As-salāmu ʿalaykum',
                      style: AppTypography.body.copyWith(
                        color: AppColors.accent,
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

          // ── Score & niveau (issue #6) ──────────────────────────────
          _ScoreSection(globalStreak: streak),
          const SizedBox(height: AppSpacing.s4),

          // ── Prochaine prière ───────────────────────────────────────
          _NextPrayerCard(
            state: data,
            onConfigurePrayers: onConfigurePrayers,
            onOpenSalat: onOpenSalat,
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── Niyyah du jour ─────────────────────────────────────────
          const _NiyyahCard(),

          // D-25 : confirmation avant déconnexion via AppDialog DS.
          if (onSignOut != null) ...[
            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: 'Se déconnecter',
              variant: AppButtonVariant.ghost,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) => AppDialog(
                  title: 'Se déconnecter ?',
                  body:
                      "Vous devrez vous reconnecter pour accéder à l'application.",
                  confirmLabel: 'Se déconnecter',
                  cancelLabel: 'Annuler',
                  isDangerous: true,
                  onConfirm: () {
                    Navigator.pop(ctx);
                    onSignOut!();
                  },
                  onCancel: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
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

/// Section score du dashboard : score card + grille de stats (issue #6).
///
/// Consume [userScoreProvider] de façon isolée pour que son chargement /
/// erreur ne fasse pas vaciller le reste du dashboard.
class _ScoreSection extends ConsumerWidget {
  final int globalStreak;
  const _ScoreSection({required this.globalStreak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(userScoreProvider);

    // UX-3 : câblage des labels salat + habitudes sur les données réelles.
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

    return scoreAsync.when(
      loading: () => const _ScoreCardSkeleton(),
      error: (e, st) {
        appLog.w('userScoreProvider error', error: e, stackTrace: st);
        return const SizedBox.shrink();
      },
      data: (score) {
        if (score == null) return const SizedBox.shrink();
        return Column(
          children: [
            DashboardScoreCard(score: score),
            const SizedBox(height: AppSpacing.s3),
            DashboardStatsGrid(
              streakDays: globalStreak,
              salatLabel: salatLabel,
              habitsLabel: habitsLabel,
              weeklyRank: score.weeklyRank,
            ),
          ],
        );
      },
    );
  }
}

/// Skeleton sobre pendant le chargement du score (pas de spinner intrusif).
class _ScoreCardSkeleton extends StatelessWidget {
  const _ScoreCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: SizedBox(
        height: 88,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidth.indicatorStroke,
          ),
        ),
      ),
    );
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
                        size: 18,
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
                  // Audit TL §B.2 PR #42 : countdown live via dashboardTickerProvider
                  // (StreamProvider 30s), scoped sur ce sous-widget pour éviter le
                  // rebuild storm sur le DashboardNotifier (qui re-fetcherait les
                  // horaires à chaque tick).
                  _RemainingLabel(
                    initialNow: state.nowUtc,
                    nextUtc: next.timeUtc,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sous-widget Consumer qui watch [dashboardTickerProvider] — seul lui
/// rebuild toutes les 30s. Le reste de la card / ListView reste statique
/// entre les ticks. Cf. audit TL §B.2 PR #42.
///
/// UX-7 : quand le compte à rebours atteint zéro, invalide [dashboardNotifierProvider]
/// une seule fois (garde `_invalidated`) pour recharger la prochaine prière.
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

/// Card "Niyyah du jour" avec fond vidéo + overlay dégradé (issue #79).
///
/// La vidéo `01.mp4` tourne en boucle muette. Le texte est superposé
/// en bas-gauche via un dégradé noir semi-transparent.
class _NiyyahCard extends StatelessWidget {
  const _NiyyahCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AppVideoBackground(
        assetPath: 'assets/media/01.mp4',
        height: 120,
        borderRadius: BorderRadius.circular(AppRadius.card),
        overlay: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.s4),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Niyyah du jour',
                style: AppTypography.h3.copyWith(color: AppColors.bgSurface),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                'Je fais cela pour plaire à Allah.',
                style: AppTypography.body.copyWith(
                  color: AppColors.bgSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    return Container(
      width: 36,
      height: 36,
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

class _GenericError extends ConsumerWidget {
  const _GenericError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Message FR neutre, sans détail technique (audit TL §B.2 PR #42).
    // L'erreur précise est loggée via appLog côté caller.
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
