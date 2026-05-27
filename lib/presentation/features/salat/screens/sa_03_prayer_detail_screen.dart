import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_detail_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/prayer_status_visuals.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/status_picker_bottom_sheet.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';

// ── Données statiques ─────────────────────────────────────────────────────────

/// Noms arabes des prières (article défini, sans diacritiques) — SA-03.
const Map<String, String> _arabicPrayerNames = {
  'fajr': 'الفجر',
  'dhuhr': 'الظهر',
  'asr': 'العصر',
  'maghrib': 'المغرب',
  'isha': 'العشاء',
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Extrait l'horaire de [prayerName] depuis [times], ou `null` si inconnu.
DateTime? _extractPrayerTime(PrayerTimes times, String prayerName) {
  return switch (prayerName) {
    'fajr' => times.fajr,
    'dhuhr' => times.dhuhr,
    'asr' => times.asr,
    'maghrib' => times.maghrib,
    'isha' => times.isha,
    _ => null,
  };
}

/// Formate l'horaire local + le temps restant avant la prière.
///
/// Exemples : "04:21 · dans 1h 05min" ou "04:21" (si heure dépassée).
String _countdownText(DateTime prayerTimeUtc) {
  final local = prayerTimeUtc.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final diff = prayerTimeUtc.difference(DateTime.now());
  if (diff.isNegative) return '$hh:$mm';
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  if (h > 0) {
    return '$hh:$mm · dans ${h}h ${m.toString().padLeft(2, '0')}min';
  }
  return '$hh:$mm · dans ${m}min';
}

// ── Écran ─────────────────────────────────────────────────────────────────────

/// SL-DETAIL — Écran détail d'une prière (wireframe SA-03).
///
/// Structure :
/// 1. Hero vidéo plein-largeur — bouton ×, nom arabe, nom latin, horaire +
///    countdown.
/// 2. Ligne statut actuel (dot coloré + label).
/// 3. Section **MARQUER COMME** — grille 2 × 2 d'actions directes
///    (À l'heure / En retard / Manquée / Réinitialiser).
/// 4. Toggle **Marquer comme rattrapée**.
/// 5. Section **CETTE SEMAINE** — heatmap 7 jours cliquables.
class Sa03PrayerDetailScreen extends ConsumerWidget {
  /// Nom canonique de la prière (`fajr` / `dhuhr` / `asr` / `maghrib` / `isha`).
  final String prayerName;

  /// Rappel de navigation retour (ferme l'écran).
  final VoidCallback onBack;

  const Sa03PrayerDetailScreen({
    super.key,
    required this.prayerName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(prayerDetailNotifierProvider(prayerName));
    final todayAsync = ref.watch(todaySalatNotifierProvider);

    final label = PrayerNameLabels.label(prayerName);
    final arabic = _arabicPrayerNames[prayerName] ?? prayerName;

    final todaySalatVal = todayAsync.valueOrNull;
    final prayerTime = todaySalatVal == null
        ? null
        : _extractPrayerTime(todaySalatVal.prayerTimes, prayerName);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidth.indicatorStroke,
          ),
        ),
        error: (_, _) => const _ErrorView(),
        data: (state) {
          final statuses = state.weekStatuses;
          final todayDate = state.weekDays.last.date;
          final todayStatus = statuses.last;
          final notifier =
              ref.read(prayerDetailNotifierProvider(prayerName).notifier);

          return CustomScrollView(
            slivers: [
              // ── Hero vidéo ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroSection(
                  arabic: arabic,
                  latin: label,
                  prayerTime: prayerTime,
                  onBack: onBack,
                ),
              ),

              // ── Corps ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s4,
                  AppSpacing.s4,
                  AppSpacing.s8,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Statut courant ─────────────────────────────
                    _StatusRow(status: todayStatus),
                    const SizedBox(height: AppSpacing.s5),

                    // ── MARQUER COMME ──────────────────────────────
                    _MarkAsSection(
                      onMark: (s) =>
                          notifier.markDay(dayUtc: todayDate, status: s),
                    ),
                    const SizedBox(height: AppSpacing.s4),

                    // ── Toggle rattrapée ───────────────────────────
                    _MakeupToggleRow(
                      isMakeup: todayStatus == PrayerStatus.makeup,
                      onToggle: (v) => notifier.markDay(
                        dayUtc: todayDate,
                        status:
                            v ? PrayerStatus.makeup : PrayerStatus.pending,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s5),

                    // ── CETTE SEMAINE ──────────────────────────────
                    _WeekSection(
                      state: state,
                      onDayTapped: (day, current) async {
                        final picked =
                            await StatusPickerBottomSheet.show(
                          context,
                          prayerLabel: label,
                          current: current,
                        );
                        if (!context.mounted) return;
                        if (picked == null || picked == current) return;
                        await notifier.markDay(
                            dayUtc: day, status: picked);
                      },
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

/// Bandeau vidéo 200 dp avec overlay gradient, bouton ×, et infos prière.
class _HeroSection extends StatelessWidget {
  final String arabic;
  final String latin;
  final DateTime? prayerTime;
  final VoidCallback onBack;

  const _HeroSection({
    required this.arabic,
    required this.latin,
    required this.prayerTime,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: AppComponentSize.heroVideo,
      child: Stack(
        children: [
          // Fond vidéo
          const AppVideoBackground(
            assetPath: 'assets/media/07.mp4',
            height: AppComponentSize.heroVideo,
          ),

          // Dégradé ascendant (transparent → videoOverlayBottom)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.transparent,
                    AppColors.videoOverlayBottom,
                  ],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
          ),

          // Bouton fermer (×) — haut droite avec safe area
          Positioned(
            top: topPad + AppSpacing.s2,
            right: AppSpacing.s4,
            child: Semantics(
              button: true,
              label: 'Fermer',
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: AppComponentSize.touchTarget,
                  height: AppComponentSize.touchTarget,
                  decoration: BoxDecoration(
                    color: AppColors.overlayDark.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.x,
                    color: AppColors.videoOverlayText,
                    size: AppIconSize.rg,
                  ),
                ),
              ),
            ),
          ),

          // Infos prière — bas gauche
          Positioned(
            bottom: AppSpacing.s4,
            left: AppSpacing.s4,
            // Marge droite : laisse la place au bouton × (touchTarget + s4*2)
            right: AppComponentSize.touchTarget + AppSpacing.s8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(
                    arabic,
                    style: AppTypography.arabicHero.copyWith(
                      color: AppColors.videoOverlayText,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  latin,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.videoOverlayText,
                  ),
                ),
                if (prayerTime != null) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    _countdownText(prayerTime!),
                    style: AppTypography.caption.copyWith(
                      color:
                          AppColors.videoOverlayText.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Statut courant ────────────────────────────────────────────────────────────

/// Ligne compacte : dot coloré + "Statut actuel : {libellé}".
class _StatusRow extends StatelessWidget {
  final PrayerStatus status;
  const _StatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = PrayerStatusVisuals.color(status);
    return Row(
      children: [
        Container(
          width: AppComponentSize.dotSize,
          height: AppComponentSize.dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(
          'Statut actuel : ${PrayerStatusVisuals.label(status)}',
          style: AppTypography.body,
        ),
      ],
    );
  }
}

// ── Section MARQUER COMME ─────────────────────────────────────────────────────

/// Grille 2 × 2 d'actions directes : À l'heure / En retard / Manquée /
/// Réinitialiser.
class _MarkAsSection extends StatelessWidget {
  final void Function(PrayerStatus) onMark;
  const _MarkAsSection({required this.onMark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MARQUER COMME', style: AppTypography.label),
        const SizedBox(height: AppSpacing.s3),

        // Ligne 1 : À l'heure | En retard
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: "À l'heure",
                status: PrayerStatus.onTime,
                onTap: () => onMark(PrayerStatus.onTime),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: _ActionButton(
                label: 'En retard',
                status: PrayerStatus.late,
                onTap: () => onMark(PrayerStatus.late),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),

        // Ligne 2 : Manquée | Réinitialiser
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Manquée',
                status: PrayerStatus.missed,
                onTap: () => onMark(PrayerStatus.missed),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: _ActionButton(
                label: 'Réinitialiser',
                status: PrayerStatus.pending,
                onTap: () => onMark(PrayerStatus.pending),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bouton d'action coloré selon [status] — utilisé dans la grille MARQUER COMME.
class _ActionButton extends StatelessWidget {
  final String label;
  final PrayerStatus status;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = PrayerStatusVisuals.color(status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s3,
          horizontal: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: AppBorderWidth.thin,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.label.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

// ── Toggle rattrapée ──────────────────────────────────────────────────────────

/// Ligne card avec Switch iOS-style — active/désactive `PrayerStatus.makeup`.
class _MakeupToggleRow extends StatelessWidget {
  final bool isMakeup;
  final void Function(bool) onToggle;

  const _MakeupToggleRow({
    required this.isMakeup,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
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
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marquer comme rattrapée', style: AppTypography.h3),
                SizedBox(height: AppSpacing.s1),
                Text('À effectuer plus tard', style: AppTypography.caption),
              ],
            ),
          ),
          Switch(value: isMakeup, onChanged: onToggle),
        ],
      ),
    );
  }
}

// ── Section CETTE SEMAINE ─────────────────────────────────────────────────────

/// Heatmap 7 jours (lundi → dimanche local) avec pastilles colorées.
class _WeekSection extends StatelessWidget {
  final PrayerDetailState state;
  final void Function(DateTime, PrayerStatus) onDayTapped;

  const _WeekSection({
    required this.state,
    required this.onDayTapped,
  });

  static const String _legendTooltip =
      "À l'heure · En retard · Rattrapée · Manquée · Non priée";

  @override
  Widget build(BuildContext context) {
    final statuses = state.weekStatuses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('CETTE SEMAINE', style: AppTypography.label),
            Spacer(),
            Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: _legendTooltip,
              child: Icon(
                LucideIcons.info,
                size: AppIconSize.sm,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        AppCard(
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _DayPastille(
                    date: state.weekDays[i].date,
                    status: statuses[i],
                    onTap: () =>
                        onDayTapped(state.weekDays[i].date, statuses[i]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pastille jour ─────────────────────────────────────────────────────────────

/// Pastille cliquable : initiale du jour + cercle coloré avec le numéro.
class _DayPastille extends StatelessWidget {
  final DateTime date;
  final PrayerStatus status;
  final VoidCallback onTap;

  const _DayPastille({
    required this.date,
    required this.status,
    required this.onTap,
  });

  static const _weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final wd = _weekdayLabels[(local.weekday - 1) % 7];
    final color = PrayerStatusVisuals.color(status);
    final isPending = status == PrayerStatus.pending;

    return Semantics(
      button: true,
      label: 'Statut $wd ${local.day} : ${PrayerStatusVisuals.label(status)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s2,
            vertical: AppSpacing.s1,
          ),
          child: Column(
            children: [
              Text(
                wd,
                style:
                    AppTypography.label.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s1),
              Container(
                width: AppComponentSize.weekDot,
                height: AppComponentSize.weekDot,
                decoration: BoxDecoration(
                  color: isPending
                      ? AppColors.bgInput
                      : color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPending ? AppColors.borderEmphasis : color,
                    width: AppBorderWidth.thin,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${local.day}',
                  style: AppTypography.body.copyWith(
                    // D-31 : textSecondary pour contraste suffisant sur pending.
                    color: isPending ? AppColors.textSecondary : color,
                    fontWeight: FontWeight.w600,
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

// ── Vue erreur ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Text(
          "Impossible de charger l'historique.\nMerci de réessayer plus tard.",
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
