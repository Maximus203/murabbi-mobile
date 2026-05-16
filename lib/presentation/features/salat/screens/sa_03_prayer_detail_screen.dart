import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_detail_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/prayer_status_visuals.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/status_picker_bottom_sheet.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';

/// SL-DETAIL — Écran détail d'une prière (issue #50).
///
/// Vue centrée sur **une prière** (Fajr/Dhuhr/Asr/Maghrib/Isha) avec :
/// - statut courant + libellé,
/// - bouton "Modifier" DS-compliant (D-04 / D-20 — issue #99),
/// - heatmap 7 jours (lundi → dimanche local) avec pastilles colorées,
/// - tap sur une pastille → bottom sheet pour re-éditer le statut.
/// - légende supprimée (D-26 — issue #99) : les pastilles colorées + Semantics
///   suffisent ; un tooltip info est disponible dans le header si besoin.
class Sa03PrayerDetailScreen extends ConsumerWidget {
  final String prayerName;
  final VoidCallback onBack;

  const Sa03PrayerDetailScreen({
    super.key,
    required this.prayerName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(prayerDetailNotifierProvider(prayerName));
    final label = PrayerNameLabels.label(prayerName);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: label, onBack: onBack),
      body: asyncState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => const _ErrorView(),
        data: (state) => _DetailBody(
          state: state,
          prayerLabel: label,
          onDayTapped: (day, currentStatus) async {
            final picked = await StatusPickerBottomSheet.show(
              context,
              prayerLabel: label,
              current: currentStatus,
            );
            if (picked == null || picked == currentStatus) return;
            await ref
                .read(prayerDetailNotifierProvider(prayerName).notifier)
                .markDay(dayUtc: day, status: picked);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final PrayerDetailState state;
  final String prayerLabel;
  final void Function(DateTime dayUtc, PrayerStatus current) onDayTapped;

  const _DetailBody({
    required this.state,
    required this.prayerLabel,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = state.weekStatuses;
    final today = state.weekDays.last;
    final todayStatus = statuses.last;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        // ── Header vidéo décoratif 200px (maquette SA-03 — issue #72) ──────
        const AppVideoBackground(
          assetPath: 'assets/media/07.mp4',
          height: 200,
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Statut courant ─────────────────────────────────────────
        AppCard(
          child: Row(
            children: [
              Icon(
                PrayerStatusVisuals.icon(todayStatus),
                size: 28,
                color: PrayerStatusVisuals.color(todayStatus),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AUJOURD'HUI",
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      PrayerStatusVisuals.label(todayStatus),
                      style: AppTypography.h2,
                    ),
                  ],
                ),
              ),
              // D-04 / D-20 (issue #99) : TextButton Material remplacé par
              // AppButton.link dans un Flexible pour éviter tout overflow.
              Flexible(
                fit: FlexFit.loose,
                child: AppButton(
                  label: 'Modifier',
                  variant: AppButtonVariant.link,
                  onPressed: () => onDayTapped(today.date, todayStatus),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s5),

        // ── Heatmap 7 jours ────────────────────────────────────────
        Row(
          children: [
            Text(
              '7 DERNIERS JOURS',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            // D-26 (issue #99) : légende supprimée (doublon avec pastilles
            // colorées + Semantics). Tooltip info pour accessibilité.
            const Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: _legendTooltip,
              child: Icon(
                LucideIcons.info,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _DayPastille(
                  date: state.weekDays[i].date,
                  status: statuses[i],
                  onTap: () => onDayTapped(state.weekDays[i].date, statuses[i]),
                ),
            ],
          ),
        ),
        // D-26 : _LegendChip supprimé — cf. décision ci-dessus.
      ],
    );
  }

  /// Texte de la légende accessible via le tooltip (D-26).
  static const String _legendTooltip =
      'À l\'heure · En retard · Rattrapée · Manquée · Non priée';
}

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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s2,
            vertical: AppSpacing.s1,
          ),
          child: Column(
            children: [
              Text(
                wd,
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
              Container(
                width: 28,
                height: 28,
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
                    color: isPending ? AppColors.textTertiary : color,
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
