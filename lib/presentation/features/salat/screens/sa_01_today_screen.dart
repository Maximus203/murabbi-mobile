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
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';


/// SA-01 — Écran "Aujourd'hui" Salat (slice 3.C.3).
///
/// Affiche les 5 prières du jour avec leur horaire local et leur statut.
/// D-22 (issue #98) : tap court → navigation SA-03 (Option A retenue — décision UX
/// à valider avec Cherif). Le changement de statut se fait depuis SA-03.
/// Si l'utilisateur n'a pas configuré ses settings (`PrayerFailure
/// .settingsNotConfigured`), propose un CTA qui invoque [onConfigureSettings]
/// — le routing concret est délégué au caller (slice 3.C.3c).
class Sa01TodayScreen extends ConsumerWidget {
  final VoidCallback onConfigureSettings;

  /// Callback navigation vers SA-03 (D-22 — Option A). Optionnel pour ne
  /// pas casser les tests existants qui n'instancient pas cette dépendance.
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
      appBar: const AppHeader.title(title: "Aujourd'hui"),
      body: state.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, stackTrace) {
          if (e is PrayerSettingsNotConfiguredFailure) {
            return _NotConfiguredView(onConfigure: onConfigureSettings);
          }
          // Audit TL §B.2 (PR #38) : ne pas exposer `e.toString()` brut
          // (risque de leak Postgrest/UX dégradée). Message FR neutre côté
          // UI, détail technique loggé pour debug.
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
          // D-22 (issue #98) — Option A : tap → navigation SA-03.
          // Décision UX à valider avec Cherif (cf. rapport audit D-22).
          onPrayerTapped: onOpenDetail,
        ),
      ),
    );
  }
}

class _PrayersList extends StatelessWidget {
  final TodaySalatState data;

  /// Callback de navigation SA-03 (D-22 Option A). Null si le caller ne
  /// fournit pas de navigation (rétrocompatibilité tests).
  final ValueChanged<String>? onPrayerTapped;

  const _PrayersList({
    required this.data,
    this.onPrayerTapped,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(data.prayerDay, data.prayerTimes);
    final completed = rows
        .where((r) => r.status != PrayerStatus.pending)
        .length;

    // D-19 (issue #98) : identifie la prochaine prière non priée.
    final now = DateTime.now().toUtc();
    final nextIndex = _nextPrayerIndex(rows, now);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        // Bandeau vidéo décoratif 130px (maquette ScreenSL01 — issue #71).
        AppVideoBackground(
          assetPath: 'assets/media/09.mp4',
          height: 130,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        const SizedBox(height: AppSpacing.s3),
        Text('$completed / 5 prières', style: AppTypography.label),
        const SizedBox(height: AppSpacing.s3),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
            child: _PrayerRow(
              row: rows[i],
              isPast: rows[i].utcTime.isBefore(now),
              isNext: i == nextIndex,
              onTap: onPrayerTapped == null
                  ? null
                  : () => onPrayerTapped!(rows[i].name),
            ),
          ),
      ],
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

  /// Retourne l'index de la prochaine prière (première prière future encore
  /// pending). Retourne -1 si toutes les prières sont passées ou priées.
  static int _nextPrayerIndex(List<_RowData> rows, DateTime now) {
    for (var i = 0; i < rows.length; i++) {
      if (!rows[i].utcTime.isBefore(now) &&
          rows[i].status == PrayerStatus.pending) {
        return i;
      }
    }
    return -1;
  }
}

class _RowData {
  final String name;
  final DateTime utcTime;
  final PrayerStatus status;
  const _RowData(this.name, this.utcTime, this.status);
}

/// Noms arabes des prières (D-34 — issue #98).
///
/// Affichés sous les noms latins dans chaque ligne de prière.
const Map<String, String> _arabicPrayerNames = {
  'fajr': 'فَجْر',
  'dhuhr': 'ظُهْر',
  'asr': 'عَصْر',
  'maghrib': 'مَغْرِب',
  'isha': 'عِشَاء',
};

class _PrayerRow extends StatelessWidget {
  final _RowData row;

  /// D-22 — null si la navigation SA-03 n'est pas disponible.
  final VoidCallback? onTap;

  /// D-19 — prière passée (temps UTC antérieur à maintenant).
  final bool isPast;

  /// D-19 — prière suivante à effectuer (highlight accent).
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

    // D-19 (issue #98) : opacité réduite pour les prières passées non priées.
    final opacity = isPast && row.status == PrayerStatus.pending ? 0.55 : 1.0;

    // D-19 : bordure accent sur la prochaine prière.
    final cardDecoration = isNext
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.accent, width: 1.5),
          )
        : null;

    return Opacity(
      opacity: opacity,
      child: DecoratedBox(
        decoration: cardDecoration ?? const BoxDecoration(),
        child: AppCard(
          // D-22 (issue #98) — Option A : tap → navigation SA-03.
          // Décision UX à valider avec Cherif.
          onTap: onTap,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s4,
            horizontal: AppSpacing.s4,
          ),
          child: Row(
            children: [
              Icon(
                PrayerStatusVisuals.icon(row.status),
                size: 22,
                color: PrayerStatusVisuals.color(row.status),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PrayerNameLabels.label(row.name),
                      style: AppTypography.h3,
                    ),
                    // D-34 (issue #98) : nom arabe sous le nom latin.
                    if (_arabicPrayerNames[row.name] case final arabic?
                        when arabic.isNotEmpty)
                      Text(
                        arabic,
                        style: AppTypography.caption.copyWith(
                          fontFamily: 'Noto Sans Arabic',
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Text('$hh:$mm', style: AppTypography.body),
              // Chevron toujours visible quand la navigation SA-03 est
              // disponible — indique un tap de navigation (D-22 Option A).
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.s2),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.textSecondary,
                  semanticLabel: 'Voir le détail',
                ),
              ],
            ],
          ),
        ),
      ),
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
          const Text(
            'Configurez vos prières',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s3),
          const Text(
            'Indiquez votre position et votre méthode de calcul pour afficher '
            'les horaires précis.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(label: 'Configurer les prières', onPressed: onConfigure),
        ],
      ),
    );
  }
}

class _GenericErrorView extends StatelessWidget {
  /// Callback de relance — invalide le provider pour re-fetcher les données.
  final VoidCallback? onRetry;

  const _GenericErrorView({this.onRetry});

  @override
  Widget build(BuildContext context) {
    // Message FR neutre, sans détail technique (cf. audit TL §B.2 PR #38).
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
