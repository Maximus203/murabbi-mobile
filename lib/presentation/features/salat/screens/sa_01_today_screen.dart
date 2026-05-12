import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/entities/prayer_times.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/today_salat_state.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/prayer_status_visuals.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/status_picker_bottom_sheet.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// SA-01 — Écran "Aujourd'hui" Salat (slice 3.C.3).
///
/// Affiche les 5 prières du jour avec leur horaire local et leur statut.
/// Tap sur une row → `StatusPickerBottomSheet` (Q-21 A2).
/// Si l'utilisateur n'a pas configuré ses settings (`PrayerFailure
/// .settingsNotConfigured`), propose un CTA qui invoque [onConfigureSettings]
/// — le routing concret est délégué au caller (slice 3.C.3c).
class Sa01TodayScreen extends ConsumerWidget {
  final VoidCallback onConfigureSettings;

  const Sa01TodayScreen({super.key, required this.onConfigureSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todaySalatNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: const AppHeader.title(title: "Aujourd'hui"),
      body: state.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) {
          if (e is PrayerSettingsNotConfiguredFailure) {
            return _NotConfiguredView(onConfigure: onConfigureSettings);
          }
          return _GenericErrorView(message: e.toString());
        },
        data: (data) => _PrayersList(
          data: data,
          onPrayerTapped: (prayerName, current) =>
              _handleTap(context, ref, prayerName, current),
        ),
      ),
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    String prayerName,
    PrayerStatus current,
  ) async {
    final picked = await StatusPickerBottomSheet.show(
      context,
      prayerLabel: PrayerNameLabels.label(prayerName),
      current: current,
    );
    if (picked == null || picked == current) return;
    await ref
        .read(todaySalatNotifierProvider.notifier)
        .markPrayer(prayerName: prayerName, status: picked);
  }
}

class _PrayersList extends StatelessWidget {
  final TodaySalatState data;
  final void Function(String prayerName, PrayerStatus current) onPrayerTapped;

  const _PrayersList({required this.data, required this.onPrayerTapped});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows(data.prayerDay, data.prayerTimes);
    final completed = rows
        .where((r) => r.status != PrayerStatus.pending)
        .length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        Text('$completed / 5 prières', style: AppTypography.label),
        const SizedBox(height: AppSpacing.s3),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s3),
            child: _PrayerRow(
              row: row,
              onTap: () => onPrayerTapped(row.name, row.status),
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
}

class _RowData {
  final String name;
  final DateTime utcTime;
  final PrayerStatus status;
  const _RowData(this.name, this.utcTime, this.status);
}

class _PrayerRow extends StatelessWidget {
  final _RowData row;
  final VoidCallback onTap;
  const _PrayerRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final local = row.utcTime.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return AppCard(
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
            child: Text(
              PrayerNameLabels.label(row.name),
              style: AppTypography.h3,
            ),
          ),
          Text('$hh:$mm', style: AppTypography.body),
        ],
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
  final String message;
  const _GenericErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Text(
          'Une erreur est survenue.\n$message',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
