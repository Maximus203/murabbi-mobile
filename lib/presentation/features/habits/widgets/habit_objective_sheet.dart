import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

/// Modal de saisie de l'objectif chiffré — variantes B.1 → B.4 (spec v1.5).
///
/// Affiche la progression `actualValue / targetValue [unité]` avec une couleur
/// dynamique, les contrôles incrément/décrément et saisie directe, puis le
/// bouton "Valider l'habitude" activé dès que l'objectif est atteint.
///
/// Appelée via [showHabitObjectiveSheet].
class HabitObjectiveSheet extends StatefulWidget {
  final HabitTargetValue target;

  /// Valeur déjà enregistrée aujourd'hui — `null` si aucun log.
  final int? currentValue;

  /// Appelé avec la valeur finale lorsque l'utilisateur valide.
  final void Function(int value) onValidate;

  const HabitObjectiveSheet({
    super.key,
    required this.target,
    required this.onValidate,
    this.currentValue,
  });

  @override
  State<HabitObjectiveSheet> createState() => _HabitObjectiveSheetState();
}

class _HabitObjectiveSheetState extends State<HabitObjectiveSheet> {
  late int _value;
  late TextEditingController _directController;

  int get _targetValue => widget.target.value.value;
  bool get _reached => _value >= _targetValue;

  Color get _valueColor {
    if (_value > _targetValue) return AppColors.success;
    if (_value == _targetValue) return AppColors.accent;
    return AppColors.textPrimary;
  }

  String get _unitLabel {
    final t = widget.target;
    if (t.unit == TargetUnit.custom) return t.customLabel ?? '';
    return _unitName(t.unit);
  }

  @override
  void initState() {
    super.initState();
    _value = widget.currentValue ?? 0;
    _directController = TextEditingController(text: _targetValue.toString());
  }

  @override
  void dispose() {
    _directController.dispose();
    super.dispose();
  }

  void _increment() => setState(() => _value++);

  void _decrement() => setState(() {
    if (_value > 0) _value--;
  });

  void _applyDirect() {
    final parsed = int.tryParse(_directController.text.trim());
    if (parsed != null && parsed >= 0) setState(() => _value = parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s4,
          right: AppSpacing.s4,
          top: AppSpacing.s5,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ─────────────────────────────────────────────
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Progression X / Y unité ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_value',
                  style: AppTypography.displayLg.copyWith(
                    color: _valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  ' / $_targetValue',
                  style: AppTypography.h1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  _unitLabel,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s6),

            // ── Saisie par incrément ─────────────────────────────────────
            const _SectionLabel('SAISIE PAR INCRÉMENT'),
            const SizedBox(height: AppSpacing.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepButton(
                  icon: Icons.remove,
                  onPressed: _value > 0 ? _decrement : null,
                ),
                const SizedBox(width: AppSpacing.s5),
                SizedBox(
                  width: 56,
                  child: Text(
                    '$_value',
                    style: AppTypography.h1.copyWith(color: _valueColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: AppSpacing.s5),
                _StepButton(icon: Icons.add, onPressed: _increment),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Séparateur OU ────────────────────────────────────────────
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s3,
                  ),
                  child: Text(
                    'OU',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),

            // ── Saisie directe du total ──────────────────────────────────
            const _SectionLabel('SAISIR LE TOTAL'),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _directController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.bgInput,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s3,
                        vertical: AppSpacing.s3,
                      ),
                    ),
                    style: AppTypography.body,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                TextButton(
                  onPressed: _applyDirect,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.bgInput,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: AppSpacing.s3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    'Mettre à jour',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),

            // ── Hint sous l'objectif ─────────────────────────────────────
            if (!_reached)
              Text(
                'Atteignez l\'objectif de $_targetValue $_unitLabel pour valider',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.s5),

            // ── Bouton valider ───────────────────────────────────────────
            AppButton(
              label: _reached ? '✓ Valider l\'habitude' : 'Valider l\'habitude',
              onPressed: _reached
                  ? () {
                      Navigator.of(context).pop();
                      widget.onValidate(_value);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre le modal objectif chiffré.
Future<void> showHabitObjectiveSheet(
  BuildContext context, {
  required HabitTargetValue target,
  int? currentValue,
  required void Function(int value) onValidate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (_) => HabitObjectiveSheet(
      target: target,
      currentValue: currentValue,
      onValidate: onValidate,
    ),
  );
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: AppComponentSize.touchTarget,
        height: AppComponentSize.touchTarget,
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.bgInput,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: AppIconSize.rg,
          color: enabled ? AppColors.bgSurface : AppColors.textTertiary,
        ),
      ),
    );
  }
}

String _unitName(TargetUnit unit) {
  switch (unit) {
    case TargetUnit.minutes:
      return 'min';
    case TargetUnit.hours:
      return 'h';
    case TargetUnit.pages:
      return 'pages';
    case TargetUnit.glasses:
      return 'verres';
    case TargetUnit.reps:
      return 'rép.';
    case TargetUnit.sets:
      return 'séries';
    case TargetUnit.km:
      return 'km';
    case TargetUnit.meters:
      return 'm';
    case TargetUnit.steps:
      return 'pas';
    case TargetUnit.custom:
      return '';
  }
}
