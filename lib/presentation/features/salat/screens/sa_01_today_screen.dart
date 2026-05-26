import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_state.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/prayer_status_visuals.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_skeleton.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';

/// SA-01 — Écran "Aujourd'hui" Salat (slice 3.C.3).
///
/// Affiche les 5 prières du jour avec leur horaire local et leur statut.
/// D-22 (issue #98) : tap court → navigation SA-03 (Option A retenue).
/// Si l'utilisateur n'a pas configuré ses settings ([PrayerSettingsNotConfiguredFailure]),
/// propose un CTA qui invoque [onConfigureSettings] vers SA-02.
///
/// Design : pas d'AppBar — hero vidéo full-width avec titre, date et compteur
/// en overlay. Filtre chips supprimé (conforme maquette — décision PO).
class Sa01TodayScreen extends ConsumerWidget {
  final VoidCallback onConfigureSettings;

  /// Callback navigation vers SA-03 (D-22 — Option A). Optionnel pour
  /// rétrocompatibilité avec les tests existants.
  final ValueChanged<String>? onOpenDetail;

  const Sa01TodayScreen({
    super.key,
    required this.onConfigureSettings,
    this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todaySalatNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // Pas d'AppBar — le header est intégré dans le hero vidéo.
      body: SafeArea(
        bottom: false,
        child: state.when(
          loading: () => Semantics(
            label: 'Chargement…',
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              children: const [
                AppSkeletonCard(lineCount: 3),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 3),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 3),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 3),
                SizedBox(height: AppSpacing.s3),
                AppSkeletonCard(lineCount: 3),
              ],
            ),
          ),
          error: (e, stackTrace) {
            if (e is PrayerSettingsNotConfiguredFailure) {
              return _NotConfiguredView(onConfigure: onConfigureSettings);
            }
            appLog.e(
              'Sa01TodayScreen render error',
              error: e,
              stackTrace: stackTrace,
            );
            return _GenericErrorView(
              onRetry: () => ref.invalidate(todaySalatNotifierProvider),
            );
          },
          data: (data) => _PrayersList(
            data: data,
            onPrayerTapped: onOpenDetail,
            onRefresh: () async {
              ref.invalidate(todaySalatNotifierProvider);
              await ref.read(todaySalatNotifierProvider.future);
            },
          ),
        ),
      ),
    );
  }
}

class _PrayersList extends StatelessWidget {
  final TodaySalatState data;
  final ValueChanged<String>? onPrayerTapped;
  final Future<void> Function()? onRefresh;

  const _PrayersList({required this.data, this.onPrayerTapped, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(data.prayerDay, data.prayerTimes);
    final now = DateTime.now().toUtc();
    final nextIndex = _nextPrayerIndex(rows, now);

    final onTime = rows.where((r) => r.status == PrayerStatus.onTime).length;
    final late = rows.where((r) => r.status == PrayerStatus.late).length;
    final missed = rows.where((r) => r.status == PrayerStatus.missed).length;
    final completed =
        onTime +
        late +
        rows.where((r) => r.status == PrayerStatus.makeup).length;

    // Date formatée en français
    final today = DateTime.now();
    final dateLabel = _formatDate(today);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: onRefresh ?? () async {},
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Hero vidéo avec overlay ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroSection(dateLabel: dateLabel, completed: completed),
          ),

          // ── Liste des prières ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                if (i < rows.length) {
                  final row = rows[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: _PrayerRow(
                      row: row,
                      isPast: row.utcTime.isBefore(now),
                      isNext: i == nextIndex,
                      onTap: onPrayerTapped == null
                          ? null
                          : () => onPrayerTapped!(row.name),
                    ),
                  );
                }
                // Bannière résumé en dernier élément
                if (i == rows.length) {
                  return _SummaryBanner(
                    onTime: onTime,
                    late: late,
                    missed: missed,
                  );
                }
                return null;
              }, childCount: rows.length + 1),
            ),
          ),

          // Espace pour la bottom nav
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),
        ],
      ),
    );
  }

  static List<_RowData> _buildRows(PrayerDay day, PrayerTimes times) {
    return [
      _RowData('fajr', times.fajr, day.fajr),
      _RowData('dhuhr', times.dhuhr, day.dhuhr),
      _RowData('asr', times.asr, day.asr),
      _RowData('maghrib', times.maghrib, day.maghrib),
      _RowData('isha', times.isha, day.isha),
    ];
  }

  static int _nextPrayerIndex(List<_RowData> rows, DateTime now) {
    for (var i = 0; i < rows.length; i++) {
      if (!rows[i].utcTime.isBefore(now) &&
          rows[i].status == PrayerStatus.pending) {
        return i;
      }
    }
    return -1;
  }

  static String _formatDate(DateTime date) {
    // ex. "Lundi 26 mai 2026"
    final weekdays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final months = [
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
    final wd = weekdays[(date.weekday - 1) % 7];
    final mo = months[date.month - 1];
    return '$wd ${date.day} $mo ${date.year}';
  }
}

class _RowData {
  final String name;
  final DateTime utcTime;
  final PrayerStatus status;
  const _RowData(this.name, this.utcTime, this.status);
}

/// Hero vidéo avec overlay "Prières du jour" + date + compteur.
class _HeroSection extends StatelessWidget {
  final String dateLabel;
  final int completed;

  const _HeroSection({required this.dateLabel, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const AppVideoBackground(assetPath: 'assets/media/09.mp4', height: 200),
        // Overlay dégradé bas → haut
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.transparent, AppColors.videoOverlayBottom],
              ),
            ),
          ),
        ),
        // Texte en bas de l'overlay
        Positioned(
          left: AppSpacing.s4,
          right: AppSpacing.s4,
          bottom: AppSpacing.s4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prières du jour',
                style: AppTypography.h2.copyWith(
                  color: AppColors.videoOverlayText,
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                dateLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.videoOverlayText.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              // Compteur de prières complétées
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: AppSpacing.s1,
                ),
                decoration: BoxDecoration(
                  color: AppColors.videoOverlayBottom,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$completed / 5 complétées',
                  style: AppTypography.label.copyWith(
                    color: AppColors.videoOverlayText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Noms arabes des prières (D-34 — issue #98).
const Map<String, String> _arabicPrayerNames = {
  'fajr': 'فَجْر',
  'dhuhr': 'ظُهْر',
  'asr': 'عَصْر',
  'maghrib': 'مَغْرِب',
  'isha': 'عِشَاء',
};

/// Icônes spécifiques à chaque prière.
const Map<String, IconData> _prayerIcons = {
  'fajr': LucideIcons.sunrise,
  'dhuhr': LucideIcons.sun,
  'asr': LucideIcons.sunMedium,
  'maghrib': LucideIcons.sunset,
  'isha': LucideIcons.moon,
};

class _PrayerRow extends StatelessWidget {
  final _RowData row;
  final VoidCallback? onTap;
  final bool isPast;
  final bool isNext;

  const _PrayerRow({
    required this.row,
    required this.isPast,
    required this.isNext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final local = row.utcTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final arabic = _arabicPrayerNames[row.name] ?? '';
    final prayerIcon = _prayerIcons[row.name] ?? LucideIcons.star;

    // D-19 : opacité réduite pour prières passées et non priées.
    final opacity = isPast && row.status == PrayerStatus.pending ? 0.50 : 1.0;

    // D-19 : bordure accent sur la prochaine prière.
    final cardDecoration = isNext
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.accent,
              width: AppBorderWidth.focusRing,
            ),
          )
        : null;

    final statusColor = PrayerStatusVisuals.color(row.status);
    final isPending = row.status == PrayerStatus.pending;

    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: cardDecoration ?? const BoxDecoration(),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s4,
            horizontal: AppSpacing.s4,
          ),
          child: Row(
            children: [
              // ── Icône de la prière (gauche) ─────────────────────────
              ExcludeSemantics(
                child: Icon(
                  prayerIcon,
                  size: AppIconSize.rg,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.s3),

              // ── Nom arabe (grand) + latin + heure (centre) ──────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom arabe en grand
                    if (arabic.isNotEmpty)
                      ExcludeSemantics(
                        child: Text(
                          arabic,
                          style: AppTypography.h3.copyWith(
                            fontFamily: 'Noto Sans Arabic',
                            height: 1.2,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.s1),
                    // Nom latin + heure sur la même ligne
                    Row(
                      children: [
                        Text(
                          PrayerNameLabels.label(row.name),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text('$hh:$mm', style: AppTypography.body),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s3),

              // ── Cercle de statut (droite) ────────────────────────────
              Semantics(
                label: PrayerStatusVisuals.label(row.status),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPending
                        ? AppColors.bgInput
                        : statusColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: isPending ? AppColors.borderEmphasis : statusColor,
                      width: AppBorderWidth.indicatorStroke,
                    ),
                  ),
                  child: isPending
                      ? null
                      : Icon(
                          PrayerStatusVisuals.icon(row.status),
                          size: AppIconSize.xs,
                          color: statusColor,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bannière résumé en bas de liste : nombre de prières à l'heure / en retard /
/// manquées. Visible uniquement si au moins une prière a été traitée.
class _SummaryBanner extends StatelessWidget {
  final int onTime;
  final int late;
  final int missed;

  const _SummaryBanner({
    required this.onTime,
    required this.late,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    if (onTime == 0 && late == 0 && missed == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.s2),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s3,
        horizontal: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(
            count: onTime,
            label: 'À l\'heure',
            color: AppColors.success,
          ),
          _SummaryChip(
            count: late,
            label: 'En retard',
            color: AppColors.warning,
          ),
          _SummaryChip(
            count: missed,
            label: 'Manquées',
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: AppTypography.h3.copyWith(color: color)),
        const SizedBox(height: AppSpacing.s1),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _NotConfiguredView extends StatelessWidget {
  final VoidCallback onConfigure;
  const _NotConfiguredView({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            LucideIcons.mapPin,
            size: AppIconSize.xxl,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.s6),
          const Text(
            'Configurez vos prières',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Indiquez votre position et votre méthode de calcul pour afficher '
            'les horaires précis.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(label: 'Configurer maintenant', onPressed: onConfigure),
        ],
      ),
    );
  }
}

class _GenericErrorView extends StatelessWidget {
  final VoidCallback? onRetry;

  const _GenericErrorView({this.onRetry});

  @override
  Widget build(BuildContext context) {
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
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s4),
              AppButton(
                label: 'Réessayer',
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
