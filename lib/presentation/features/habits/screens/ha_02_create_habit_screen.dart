import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// HA-02 — Formulaire de création d'habitude (slice 3.D).
///
/// Version V1 simplifiée :
/// - Nom (required)
/// - Catégorie (dropdown)
/// - Récurrence (daily / per-day / weekly avec sélecteur de jours)
/// - Points (slider 1..10)
///
/// Reporté V2 : sous-tâches, time range, target chiffré, timer. Cf.
/// `spec v1.5` et ADR-008.
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
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Category> categories) async {
    setState(() {
      _error = null;
    });
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
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Erreur : $e';
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
      body: categoriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (categories) {
          _categoryId ??= categories.firstOrNull?.id;
          return _buildForm(categories);
        },
      ),
    );
  }

  Widget _buildForm(List<Category> categories) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        AppInput(
          label: 'Nom',
          placeholder: 'ex. Lecture Coran',
          controller: _nameCtrl,
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Catégorie ──────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Catégorie', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.s3),
              DropdownButton<CategoryId>(
                isExpanded: true,
                value: _categoryId,
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name.value)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Récurrence ─────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Récurrence', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.s3),
              for (final t in [
                HabitFrequencyType.daily,
                HabitFrequencyType.perDay,
                HabitFrequencyType.weekly,
              ])
                InkWell(
                  onTap: () => setState(() => _frequencyType = t),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _frequencyType == t
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: _frequencyType == t
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: Text(
                            _frequencyLabel(t),
                            style: AppTypography.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_frequencyType == HabitFrequencyType.perDay) ...[
                const SizedBox(height: AppSpacing.s2),
                Row(
                  children: [
                    const Text('Combien de fois :'),
                    const Spacer(),
                    IconButton(
                      onPressed: _perDayFrequency > 1
                          ? () => setState(() => _perDayFrequency--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$_perDayFrequency', style: AppTypography.h3),
                    IconButton(
                      onPressed: _perDayFrequency < 10
                          ? () => setState(() => _perDayFrequency++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
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

        // ── Points ─────────────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Difficulté', style: AppTypography.h3),
                  const Spacer(),
                  Text(
                    '$_points pt${_points > 1 ? 's' : ''}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _points.toDouble(),
                min: HabitPoints.min.toDouble(),
                max: HabitPoints.max.toDouble(),
                divisions: HabitPoints.max - HabitPoints.min,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => _points = v.round()),
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

        const SizedBox(height: AppSpacing.s6),
        AppButton(
          label: _saving ? 'Enregistrement…' : 'Créer l\'habitude',
          onPressed: _saving ? null : () => _submit(categories),
        ),
        const SizedBox(height: AppSpacing.s6),
      ],
    );
  }

  static String _frequencyLabel(HabitFrequencyType t) {
    switch (t) {
      case HabitFrequencyType.daily:
        return 'Tous les jours';
      case HabitFrequencyType.perDay:
        return 'Plusieurs fois par jour';
      case HabitFrequencyType.weekly:
        return 'Jours précis de la semaine';
      case HabitFrequencyType.perWeek:
      case HabitFrequencyType.monthly:
      case HabitFrequencyType.custom:
        return t.name;
    }
  }
}

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
        width: 36,
        height: 36,
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
