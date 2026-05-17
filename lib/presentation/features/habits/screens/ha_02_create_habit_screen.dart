import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_points.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_chip.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';
import 'package:murabbi_mobile/presentation/widgets/app_logo.dart';

/// HA-02 — Formulaire de création d'habitude (spec v1.5 slice 3.D).
///
/// Refactorisé (issue #86) :
/// - Chips catégorie avec dot couleur + badge "Système"
/// - Chips fréquence en grille (Wrap)
/// - Plage horaire (TimeOfDay pickers)
/// - Notification preview
/// - Points : stepper stylisé
/// - Bouton "Créer" sticky en bas via Scaffold.bottomNavigationBar
class Ha02CreateHabitScreen extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  final VoidCallback onCancel;

  const Ha02CreateHabitScreen({
    super.key,
    required this.onCreated,
    required this.onCancel,
  });

  @override
  ConsumerState<Ha02CreateHabitScreen> createState() =>
      _Ha02CreateHabitScreenState();
}

class _Ha02CreateHabitScreenState extends ConsumerState<Ha02CreateHabitScreen> {
  final _nameCtrl = TextEditingController();
  CategoryId? _categoryId;
  HabitFrequencyType _frequencyType = HabitFrequencyType.daily;
  int _perDayFrequency = 1;
  final Set<int> _activeDays = {1, 2, 3, 4, 5, 6, 7};
  int _points = 3;
  TimeOfDay? _rangeStart;
  TimeOfDay? _rangeEnd;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _rangeStart : _rangeEnd) ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: AppColors.bgSurface,
            hourMinuteColor: AppColors.bgInput,
            dialBackgroundColor: AppColors.bgInput,
            entryModeIconColor: AppColors.accent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _rangeStart = picked;
        } else {
          _rangeEnd = picked;
        }
      });
    }
  }

  Future<void> _submit(List<Category> categories) async {
    setState(() => _error = null);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Le nom est requis.');
      return;
    }
    final catId = _categoryId ?? categories.first.id;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      setState(() => _error = 'Tu dois être connecté.');
      return;
    }

    setState(() => _saving = true);
    try {
      final habit = Habit(
        id: HabitId('habit-${DateTime.now().microsecondsSinceEpoch}'),
        name: NonEmptyString(name),
        categoryId: catId,
        frequencyType: _frequencyType,
        frequency: _frequencyType == HabitFrequencyType.perDay
            ? _perDayFrequency
            : 1,
        activeDays: Set.of(_activeDays),
        points: HabitPoints(_points),
        isSystem: false,
      );
      await ref
          .read(createHabitUseCaseProvider)
          .call(userId: user.id, habit: habit);
      await ref.read(habitsNotifierProvider.notifier).refresh();
      if (mounted) widget.onCreated();
    } catch (e, stackTrace) {
      appLog.e(
        'Ha02CreateHabitScreen submit failed',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _saving = false;
        _error = "Impossible de créer l'habitude. Réessaie dans un instant.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Nouvelle habitude',
        onBack: widget.onCancel,
      ),
      // Bouton "Créer l'habitude" sticky en bas — toujours visible
      bottomNavigationBar: categoriesAsync.maybeWhen(
        data: (cats) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            child: AppButton(
              label: _saving ? 'Enregistrement…' : "Créer l'habitude",
              onPressed: _saving ? null : () => _submit(cats),
            ),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
      body: categoriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, stackTrace) {
          appLog.e(
            'Ha02 categories load failed',
            error: e,
            stackTrace: stackTrace,
          );
          return const Center(
            child: Text(
              'Impossible de charger les catégories.',
              style: AppTypography.body,
            ),
          );
        },
        data: (categories) {
          _categoryId ??= categories.firstOrNull?.id;
          return _buildForm(categories);
        },
      ),
    );
  }

  Widget _buildForm(List<Category> categories) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s6,
      ),
      children: [
        // ── Nom ────────────────────────────────────────────────────
        AppInput(
          label: 'Nom',
          placeholder: 'ex. Lecture Coran',
          controller: _nameCtrl,
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Catégorie — chips avec dot + badge système ──────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CATÉGORIE', style: _sectionLabelStyle),
              const SizedBox(height: AppSpacing.s3),
              Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: [
                  for (final c in categories)
                    AppChip(
                      label: c.name.value,
                      selected: _categoryId == c.id,
                      onTap: () => setState(() => _categoryId = c.id),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _hexToColor(c.color.value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (c.isSystem) ...[
                            const SizedBox(width: AppSpacing.s1),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.chip,
                                ),
                              ),
                              child: Text(
                                'S',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Fréquence — chip grid ───────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FRÉQUENCE', style: _sectionLabelStyle),
              const SizedBox(height: AppSpacing.s3),
              Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: [
                  for (final t in _frequencyOptions)
                    AppChip(
                      label: _frequencyLabel(t),
                      selected: _frequencyType == t,
                      onTap: () => setState(() => _frequencyType = t),
                    ),
                ],
              ),
              // Stepper fois/jour si perDay
              if (_frequencyType == HabitFrequencyType.perDay) ...[
                const SizedBox(height: AppSpacing.s3),
                Row(
                  children: [
                    Text(
                      'Combien de fois :',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    _StepperButton(
                      icon: LucideIcons.minus,
                      onPressed: _perDayFrequency > 1
                          ? () => setState(() => _perDayFrequency--)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      '$_perDayFrequency',
                      style: AppTypography.h3.copyWith(
                        fontFamily: 'Geist Mono',
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    _StepperButton(
                      icon: LucideIcons.plus,
                      onPressed: _perDayFrequency < 10
                          ? () => setState(() => _perDayFrequency++)
                          : null,
                    ),
                  ],
                ),
              ],
              // Sélecteur de jours si weekly
              if (_frequencyType == HabitFrequencyType.weekly) ...[
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: AppSpacing.s2,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      _DayChip(
                        day: d,
                        selected: _activeDays.contains(d),
                        onTap: () => setState(() {
                          if (_activeDays.contains(d)) {
                            if (_activeDays.length > 1) _activeDays.remove(d);
                          } else {
                            _activeDays.add(d);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Plage horaire ───────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PLAGE HORAIRE', style: _sectionLabelStyle),
              const SizedBox(height: AppSpacing.s1),
              Text(
                'Heure de rappel pour la notification.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Début',
                      time: _rangeStart,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: _TimePickerButton(
                      label: 'Fin',
                      time: _rangeEnd,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Notification preview ────────────────────────────────────
        if (_nameCtrl.text.trim().isNotEmpty || _rangeStart != null) ...[
          _NotificationPreview(
            habitName: _nameCtrl.text.trim().isEmpty
                ? 'Mon habitude'
                : _nameCtrl.text.trim(),
            time: _rangeStart,
          ),
          const SizedBox(height: AppSpacing.s4),
        ],

        // ── Points / Difficulté ─────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DIFFICULTÉ', style: _sectionLabelStyle),
              const SizedBox(height: AppSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: _StyledSlider(
                      value: _points.toDouble(),
                      min: HabitPoints.min.toDouble(),
                      max: HabitPoints.max.toDouble(),
                      onChanged: (v) => setState(() => _points = v.round()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Container(
                    width: 44,
                    alignment: Alignment.center,
                    child: Text(
                      '$_points pt${_points > 1 ? 's' : ''}',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.danger),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Text(
              _error!,
              style: AppTypography.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ],
    );
  }

  static const List<HabitFrequencyType> _frequencyOptions = [
    HabitFrequencyType.daily,
    HabitFrequencyType.perDay,
    HabitFrequencyType.perWeek,
    HabitFrequencyType.weekly,
    HabitFrequencyType.monthly,
    HabitFrequencyType.custom,
  ];

  static String _frequencyLabel(HabitFrequencyType t) {
    switch (t) {
      case HabitFrequencyType.daily:
        return 'Quotidien';
      case HabitFrequencyType.perDay:
        return 'X×/jour';
      case HabitFrequencyType.perWeek:
        return '3×/sem.';
      case HabitFrequencyType.weekly:
        return 'Hebdo';
      case HabitFrequencyType.monthly:
        return 'Mensuel';
      case HabitFrequencyType.custom:
        return 'Custom';
    }
  }
}

// ── Section label style ───────────────────────────────────────────────────────

const _sectionLabelStyle = TextStyle(
  fontFamily: 'Geist',
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.8,
  color: AppColors.textSecondary,
);

// ── Notification preview widget ───────────────────────────────────────────────

/// Prévisualisation de la notification push — logo + nom + heure.
class _NotificationPreview extends StatelessWidget {
  final String habitName;
  final TimeOfDay? time;

  const _NotificationPreview({required this.habitName, this.time});

  @override
  Widget build(BuildContext context) {
    final timeLabel = time != null
        ? time!.format(context)
        : 'Heure non définie';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APERÇU NOTIFICATION',
            style: AppTypography.label.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              children: [
                const AppLogo(size: 32),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Murabbi',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        habitName,
                        style: AppTypography.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        timeLabel,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
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

// ── Time picker button ────────────────────────────────────────────────────────

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasTime = time != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: hasTime
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.bgInput,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: hasTime ? AppColors.accent : AppColors.borderEmphasis,
            width: AppBorderWidth.thin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: hasTime ? AppColors.accent : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  hasTime ? time!.format(context) : '--:--',
                  style: AppTypography.body.copyWith(
                    color: hasTime ? AppColors.accent : AppColors.textTertiary,
                    fontWeight: hasTime ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Styled slider ─────────────────────────────────────────────────────────────

class _StyledSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _StyledSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.bgInput,
        thumbColor: AppColors.accent,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayColor: AppColors.accent.withValues(alpha: 0.12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: (max - min).toInt(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Stepper button ────────────────────────────────────────────────────────────

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppColors.bgInput : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: enabled
                ? AppColors.borderEmphasis
                : AppColors.borderDefault,
            width: AppBorderWidth.thin,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ── Day chip ──────────────────────────────────────────────────────────────────

class _DayChip extends StatelessWidget {
  final int day;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderEmphasis,
            width: AppBorderWidth.thin,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _labels[day - 1],
          style: AppTypography.body.copyWith(
            color: selected ? AppColors.bgSurface : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Convertit un token couleur `#RRGGBB` en [Color].
Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
