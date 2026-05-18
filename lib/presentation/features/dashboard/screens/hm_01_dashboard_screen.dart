import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_schedule.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/presentation/common/app_video_player.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_state.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_ticker_provider.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_media.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';
import 'package:murabbi_mobile/presentation/widgets/app_progress_ring.dart';
import 'package:murabbi_mobile/services/video_service.dart';

// ignore: prefer_final_fields

/// HM-01 — Écran d'accueil Murabbi (v1.5).
///
/// Agrège : salutation, date du jour (grégorienne + hijri), prochaine prière,
/// score card avec [AppProgressRing], section habitudes avec micro-rows,
/// carte Niyyah vidéo et indicateur de série globale.
class Hm01DashboardScreen extends ConsumerWidget {
  final ValueChanged<AppBottomNavTab> onTabSelected;
  final VoidCallback onConfigurePrayers;
  final VoidCallback onOpenSalat;
  final VoidCallback? onSignOut;

  const Hm01DashboardScreen({
    super.key,
    required this.onTabSelected,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardNotifierProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final pseudo = user?.pseudo.value ?? 'Murabbi';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      bottomNavigationBar: AppBottomNav(
        active: AppBottomNavTab.home,
        onTabSelected: onTabSelected,
      ),
      body: SafeArea(
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
          ),
        ),
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

  const _DashboardBody({
    required this.data,
    required this.pseudo,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = data.nowUtc.toLocal();
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        ref.invalidate(dashboardNotifierProvider);
        // #145 : rafraîchit aussi la liste d'habitudes — une habitude créée
        // depuis HA-02 doit apparaître dans « Habitudes du jour ».
        await ref.read(habitsNotifierProvider.notifier).refresh();
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
          // #128 : le bouton cloche notification (stub `onPressed: null`)
          // a été retiré — fausse affordance. Il sera réintroduit avec la
          // navigation Notifications réelle (Phase 5).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // D-30 : salutation en label/accent UPPERCASE — convention AppTypography.label.
                    // #132 : ʿ (ayn, U+02BF) rendu □ sur certaines plateformes —
                    // remplacé par une apostrophe ASCII. Les macrons (ā/ī/ū)
                    // sont conservés (couverts par la police).
                    Text(
                      "AS-SALĀMU 'ALAYKUM",
                      style: AppTypography.label.copyWith(
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
            ],
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Prochaine prière ───────────────────────────────────────
          _NextPrayerCard(
            state: data,
            onConfigurePrayers: onConfigurePrayers,
            onOpenSalat: onOpenSalat,
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── Score & Série ──────────────────────────────────────────
          _ScoreStreakCard(data: data),
          const SizedBox(height: AppSpacing.s3),

          // ── Habitudes du jour ──────────────────────────────────────
          const _HabitsCard(),
          const SizedBox(height: AppSpacing.s3),

          // ── Niyyah vidéo ───────────────────────────────────────────
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
                      "Tu devras te reconnecter pour accéder à l'application.",
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
  // #132 : ʿ (ayn, U+02BF) remplacé par apostrophe ASCII — rendu □ sur
  // certaines plateformes. Les macrons (ā/ī/ū) sont conservés (couverts par
  // la police). Ḥ conservé pour Dhul-Ḥijjah.
  static const _hijriMonths = [
    'Muharram',
    'Safar',
    "Rabī' al-Awwal",
    "Rabī' al-Thānī",
    'Jumādā al-Ūlā',
    'Jumādā al-Ākhira',
    'Rajab',
    "Sha'bān",
    'Ramadan',
    'Shawwāl',
    "Dhul-Qa'dah",
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
            const Text('Configure tes prières', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Indique ta position et ta méthode pour afficher les '
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
class _RemainingLabel extends ConsumerWidget {
  final DateTime initialNow;
  final DateTime nextUtc;

  const _RemainingLabel({required this.initialNow, required this.nextUtc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticker = ref.watch(dashboardTickerProvider);
    final now = ticker.valueOrNull ?? initialNow;
    return Text(
      'Dans ${_formatRemaining(nextUtc, now)}',
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
/// La vidéo [AppMedia.niyyahVideoKey] est servie depuis Supabase Storage
/// (ADR-017 : vidéo in-app, disponible après authentification).
/// Elle tourne en boucle muette. Le texte est superposé en bas-gauche
/// via un dégradé noir semi-transparent.
class _NiyyahCard extends ConsumerWidget {
  const _NiyyahCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoUrl = ref
        .read(videoServiceProvider)
        .getRemoteVideoUrl(AppMedia.niyyahVideoKey);

    return AppVideoPlayer(
      url: videoUrl,
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
    );
  }
}

/// Carte Habitudes du jour — affiche les micro-rows depuis [habitsNotifierProvider].
///
/// Limite l'affichage à 5 habitudes avec un lien "Voir tout" si la liste
/// dépasse ce seuil.
class _HabitsCard extends ConsumerWidget {
  static const int _maxVisible = 5;

  const _HabitsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsNotifierProvider);

    return habitsAsync.when(
      loading: () => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, null),
            const SizedBox(height: AppSpacing.s3),
            const SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: AppBorderWidth.indicatorStroke,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (e, st) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, null),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Impossible de charger les habitudes.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      data: (allHabits) {
        // #145 : ne garder que les habitudes dues aujourd'hui. Une habitude
        // `daily` créée le jour même est due le jour même et doit donc
        // apparaître ici (cf. HabitSchedule.isDueOn).
        final today = DateTime.now();
        final habits = habitsDueOn(allHabits, today);
        final visible = habits.take(_maxVisible).toList();
        final hasMore = habits.length > _maxVisible;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, habits.length),
              if (habits.isEmpty) ...[
                const SizedBox(height: AppSpacing.s2),
                Text(
                  "Aucune habitude configurée pour aujourd'hui.",
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.s3),
                ...visible.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                    child: _HabitMicroRow(habit: h),
                  ),
                ),
                if (hasMore) ...[
                  const SizedBox(height: AppSpacing.s1),
                  GestureDetector(
                    // TODO Phase 3 : naviguer vers HA-01 via onTabSelected
                    onTap: () {},
                    child: Text(
                      'Voir tout',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  /// Ligne d'en-tête : label "HABITUDES DU JOUR" + compteur "N/9" Mono.
  Widget _buildHeader(BuildContext context, int? count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Habitudes du jour', style: AppTypography.h3),
        if (count != null)
          Text(
            // Compteur "N/9" — le dénominateur total visible (9 = exemple mock).
            // Phase 4 brancher le total réel via ScoringService.
            '$count',
            style: AppTypography.mono.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

/// Ligne compacte représentant une habitude sur le dashboard.
///
/// Composition : dot catégorie 6px · nom de l'habitude · objectif (caption Mono).
class _HabitMicroRow extends StatelessWidget {
  final Habit habit;

  const _HabitMicroRow({required this.habit});

  /// Retourne la couleur du dot depuis les tokens AppColors selon l'id catégorie.
  static Color _dotColor(String categoryId) {
    return switch (categoryId) {
      'cat-religion' => AppColors.categoryReligion,
      'cat-sport' => AppColors.categorySport,
      'cat-sante' => AppColors.categorySante,
      'cat-mental' => AppColors.categoryMental,
      'cat-social' => AppColors.categorySocial,
      _ => AppColors.textTertiary,
    };
  }

  /// Libellé de l'objectif : "X unité" pour [HabitTargetValue] /
  /// [HabitTargetTimed], vide pour [HabitTargetNone].
  static String _targetLabel(HabitTarget target) {
    return switch (target) {
      HabitTargetValue(:final value, :final unit, :final customLabel) =>
        '${value.value} ${customLabel ?? unit.name}',
      HabitTargetTimed(:final value, :final unit) =>
        '${value.value} ${unit.name}',
      HabitTargetNone() => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dot = _dotColor(habit.categoryId.value);
    final targetLabel = _targetLabel(habit.target);

    return Row(
      children: [
        // Dot catégorie 6px
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.s2),
        // Nom de l'habitude
        Expanded(
          child: Text(
            habit.name.value,
            style: AppTypography.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (targetLabel.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.s2),
          Text(
            targetLabel,
            style: AppTypography.mono.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Card score + série globale — slice 5.F.
///
/// Affiche les points hebdomadaires, le niveau courant et la série globale.
/// Si aucun score n'est encore disponible, affiche des tirets.
class _ScoreStreakCard extends StatelessWidget {
  final DashboardState data;

  const _ScoreStreakCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final level = data.currentLevel;
    final weekly = data.weeklyPoints;
    final streak = data.globalStreak;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: LucideIcons.star,
              label: 'Pts hebdo',
              value: weekly == 0 ? '—' : '$weekly',
            ),
          ),
          Container(width: 0.5, height: 32, color: AppColors.borderDefault),
          Expanded(
            child: _StatItem(
              icon: LucideIcons.flame,
              label: 'Série',
              value: streak == 0 ? '—' : '${streak}j',
            ),
          ),
          Container(width: 0.5, height: 32, color: AppColors.borderDefault),
          Expanded(
            child: _StatItem(
              icon: LucideIcons.award,
              label: 'Niveau',
              value: _levelLabel(level),
            ),
          ),
        ],
      ),
    );
  }

  static String _levelLabel(dynamic level) {
    return switch (level.toString().split('.').last) {
      'aspirant' => 'Aspirant',
      'murid' => 'Murid',
      'salik' => 'Salik',
      'mujahid' => 'Mujahid',
      'wali' => 'Wali',
      'murabbi' => 'Murabbi',
      _ => '—',
    };
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(height: AppSpacing.s1),
          Text(value, style: AppTypography.h3, textAlign: TextAlign.center),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GenericError extends StatelessWidget {
  const _GenericError();

  @override
  Widget build(BuildContext context) {
    // Message FR neutre, sans détail technique (audit TL §B.2 PR #42).
    // L'erreur précise est loggée via appLog côté caller.
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Text(
          'Une erreur est survenue.\nMerci de réessayer plus tard.',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
