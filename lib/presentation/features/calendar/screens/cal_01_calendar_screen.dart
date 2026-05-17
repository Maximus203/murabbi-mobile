import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/habit_log.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/build_month_grid_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/calendar_filter.dart';
import 'package:murabbi_mobile/domain/use_cases/calendar/compute_day_color_use_case.dart';
import 'package:murabbi_mobile/presentation/features/calendar/providers/calendar_month_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_filter_chips.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// Noms FR des mois (index 1..12).
const List<String> _monthNames = [
  '',
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// Initiales des jours de semaine (lundi → dimanche).
const List<String> _weekdayInitials = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// CAL-01 — Calendrier historique (issue #7, Phase 6).
///
/// Navigation mois (< Mai 2026 >), onglets de filtre Tout / Salat /
/// Habitudes, grille des jours colorée par statut (via
/// [ComputeDayColorUseCase]) et carte de stats du jour sélectionné.
class Cal01CalendarScreen extends ConsumerStatefulWidget {
  /// Retour vers l'écran précédent.
  final VoidCallback onBack;

  const Cal01CalendarScreen({super.key, required this.onBack});

  @override
  ConsumerState<Cal01CalendarScreen> createState() =>
      _Cal01CalendarScreenState();
}

class _Cal01CalendarScreenState extends ConsumerState<Cal01CalendarScreen> {
  static const _gridBuilder = BuildMonthGridUseCase();

  CalendarFilter _filter = CalendarFilter.all;
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final cursor = ref.watch(calendarMonthCursorProvider);
    final monthData = ref.watch(calendarMonthDataProvider);
    final grid = _gridBuilder(year: cursor.year, month: cursor.month);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: 'Calendrier', onBack: widget.onBack),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          _MonthNavBar(
            label: '${_monthNames[cursor.month]} ${cursor.year}',
            onPrevious: () {
              ref.read(calendarMonthCursorProvider.notifier).previousMonth();
              setState(() => _selectedDay = null);
            },
            onNext: () {
              ref.read(calendarMonthCursorProvider.notifier).nextMonth();
              setState(() => _selectedDay = null);
            },
          ),
          const SizedBox(height: AppSpacing.s4),
          AppFilterChips(
            labels: const ['Tout', 'Salat', 'Habitudes'],
            selectedIndex: _filter.index,
            onChanged: (i) =>
                setState(() => _filter = CalendarFilter.values[i]),
          ),
          const SizedBox(height: AppSpacing.s4),
          monthData.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.s8),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: AppBorderWidth.indicatorStroke,
                ),
              ),
            ),
            error: (e, st) {
              appLog.e('CAL-01 month data error', error: e, stackTrace: st);
              return const _CalendarError();
            },
            data: (data) {
              if (data.isEmpty) return const _CalendarEmpty();
              return Column(
                children: [
                  _WeekdayHeader(),
                  const SizedBox(height: AppSpacing.s2),
                  _DayGrid(
                    grid: grid,
                    data: data,
                    filter: _filter,
                    selectedDay: _selectedDay,
                    onDaySelected: (d) => setState(() => _selectedDay = d),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  if (_selectedDay != null)
                    _DayStatsCard(
                      day: _selectedDay!,
                      data: data[_selectedDay!] ?? const CalendarDayData(),
                      filter: _filter,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
      ),
    );
  }
}

/// Barre de navigation de mois — < Mois Année >.
class _MonthNavBar extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthNavBar({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Mois précédent',
          onPressed: onPrevious,
          icon: Icon(lu(LucideIcons.chevronLeft), size: 22),
          color: AppColors.textPrimary,
        ),
        Text(label, style: AppTypography.h3),
        IconButton(
          tooltip: 'Mois suivant',
          onPressed: onNext,
          icon: Icon(lu(LucideIcons.chevronRight), size: 22),
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}

/// En-tête des 7 jours de la semaine.
class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final initial in _weekdayInitials)
          Expanded(
            child: Center(
              child: Text(
                initial,
                style: AppTypography.label.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Grille des jours du mois — 7 colonnes, cellules colorées par statut.
class _DayGrid extends StatelessWidget {
  final MonthGrid grid;
  final Map<DateTime, CalendarDayData> data;
  final CalendarFilter filter;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _DayGrid({
    required this.grid,
    required this.data,
    required this.filter,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      for (var i = 0; i < grid.leadingBlanks; i++) const SizedBox.shrink(),
      for (final day in grid.days)
        _DayCell(
          day: day,
          color: _colorFor(day),
          selected: selectedDay == day,
          onTap: () => onDaySelected(day),
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.s2,
      crossAxisSpacing: AppSpacing.s2,
      children: cells,
    );
  }

  DayColor _colorFor(DateTime day) {
    final d = data[day] ?? const CalendarDayData();
    return dayColorForFilter(
      filter: filter,
      prayerStatuses: d.prayerStatuses,
      habitStatuses: d.habitStatuses,
    );
  }
}

/// Cellule d'un jour — fond coloré selon la sévérité, opacité selon le
/// taux de complétion.
class _DayCell extends StatelessWidget {
  final DateTime day;
  final DayColor color;
  final bool selected;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = _severityColor(color.worst);
    // Opacité minimale 0.2 pour que le jour reste lisible même peu rempli.
    final fill = color.worst == DayStatusSeverity.empty
        ? AppColors.bgInput
        : base.withValues(alpha: 0.2 + 0.8 * color.fillPercent);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: selected
              ? Border.all(
                  color: AppColors.accent,
                  width: AppBorderWidth.focusRing,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: AppTypography.caption.copyWith(
            color: color.worst == DayStatusSeverity.empty
                ? AppColors.textSecondary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  static Color _severityColor(DayStatusSeverity s) {
    switch (s) {
      case DayStatusSeverity.empty:
        return AppColors.bgInput;
      case DayStatusSeverity.success:
        return AppColors.success;
      case DayStatusSeverity.late:
        return AppColors.warning;
      case DayStatusSeverity.missed:
        return AppColors.danger;
    }
  }
}

/// Carte de statistiques du jour sélectionné.
class _DayStatsCard extends StatelessWidget {
  final DateTime day;
  final CalendarDayData data;
  final CalendarFilter filter;

  const _DayStatsCard({
    required this.day,
    required this.data,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final color = dayColorForFilter(
      filter: filter,
      prayerStatuses: data.prayerStatuses,
      habitStatuses: data.habitStatuses,
    );
    final percent = (color.fillPercent * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day} ${_monthNames[day.month]} ${day.year}',
            style: AppTypography.h3,
          ),
          const SizedBox(height: AppSpacing.s3),
          if (filter != CalendarFilter.habits)
            _StatRow(
              label: 'Prières validées',
              value:
                  '${_validatedPrayers(data.prayerStatuses)}/${data.prayerStatuses.length}',
            ),
          if (filter != CalendarFilter.salat)
            _StatRow(
              label: 'Habitudes validées',
              value:
                  '${_validatedHabits(data.habitStatuses)}/${data.habitStatuses.length}',
            ),
          const SizedBox(height: AppSpacing.s2),
          _StatRow(label: 'Complétion', value: '$percent %'),
        ],
      ),
    );
  }

  static int _validatedPrayers(List<PrayerStatus> statuses) {
    return statuses
        .where(
          (s) =>
              s == PrayerStatus.onTime ||
              s == PrayerStatus.late ||
              s == PrayerStatus.makeup,
        )
        .length;
  }

  static int _validatedHabits(List<HabitLogStatus> statuses) {
    return statuses
        .where((s) => s == HabitLogStatus.onTime || s == HabitLogStatus.late)
        .length;
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}

/// Empty state CAL-01 — aucun historique pour ce mois.
class _CalendarEmpty extends StatelessWidget {
  const _CalendarEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Icon(
              LucideIcons.calendarRange,
              size: 36,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          const Text(
            'Aucune activité ce mois-ci',
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Tes prières et habitudes validées apparaîtront ici jour après jour.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CalendarError extends StatelessWidget {
  const _CalendarError();

  @override
  Widget build(BuildContext context) {
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
