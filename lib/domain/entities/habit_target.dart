import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/domain/value_objects/target_value.dart';

/// Composition `HabitTarget` côté Dart, repliée sur le SQL flat (5 colonnes
/// `target_value`, `target_unit`, `target_unit_custom`, `has_timer`,
/// `subtasks_required`) du côté Supabase.
///
/// Trois variantes exhaustives, vérifiées par le compilateur via la nature
/// `sealed` (Dart 3) :
///
/// - [HabitTargetNone] — pas d'objectif chiffré, pas de timer.
/// - [HabitTargetValue] — objectif chiffré (`pages`, `glasses`, `custom`, …)
///   sans timer.
/// - [HabitTargetTimed] — objectif chiffré + timer in-app, unité forcément
///   `minutes` ou `hours` (cf. spec v1.5 § 3.5, contrainte `chk_timer_unit`).
///
/// Voir `docs/adr/ADR-008-habit-v15-extensions.md` pour la justification
/// (alignement SQL ↔ Zod admin ↔ sealed Dart).
sealed class HabitTarget extends Equatable {
  const HabitTarget();

  /// Variante « pas d'objectif chiffré ».
  const factory HabitTarget.none() = HabitTargetNone;

  /// Variante « objectif chiffré sans timer ».
  factory HabitTarget.value({
    required TargetValue value,
    required TargetUnit unit,
    String? customLabel,
  }) = HabitTargetValue;

  /// Variante « objectif chiffré + timer ».
  factory HabitTarget.timed({
    required TargetValue value,
    required TargetUnit unit,
  }) = HabitTargetTimed;

  bool get hasValue;
  bool get hasTimer;
}

class HabitTargetNone extends HabitTarget {
  const HabitTargetNone();

  @override
  bool get hasValue => false;

  @override
  bool get hasTimer => false;

  @override
  List<Object?> get props => const [];
}

class HabitTargetValue extends HabitTarget {
  static const int customLabelMaxLength = 30;

  final TargetValue value;
  final TargetUnit unit;
  final String? customLabel;

  HabitTargetValue({
    required this.value,
    required this.unit,
    String? customLabel,
  }) : customLabel = _validateCustomLabel(unit, customLabel);

  static String? _validateCustomLabel(TargetUnit unit, String? raw) {
    if (unit == TargetUnit.custom) {
      if (raw == null || raw.trim().isEmpty) {
        throw ArgumentError.value(
          raw,
          'customLabel',
          'HabitTarget.value with unit=custom requires a non-empty customLabel',
        );
      }
      final trimmed = raw.trim();
      if (trimmed.runes.length > customLabelMaxLength) {
        throw ArgumentError.value(
          raw,
          'customLabel',
          'HabitTarget.value customLabel must be <= $customLabelMaxLength chars',
        );
      }
      return trimmed;
    }
    if (raw != null) {
      throw ArgumentError.value(
        raw,
        'customLabel',
        'HabitTarget.value customLabel is only valid when unit == TargetUnit.custom',
      );
    }
    return null;
  }

  @override
  bool get hasValue => true;

  @override
  bool get hasTimer => false;

  @override
  List<Object?> get props => [value, unit, customLabel];
}

class HabitTargetTimed extends HabitTarget {
  final TargetValue value;
  final TargetUnit unit;

  HabitTargetTimed({required this.value, required this.unit}) {
    if (!unit.isTimeBased) {
      throw ArgumentError.value(
        unit,
        'unit',
        'HabitTarget.timed requires unit ∈ {minutes, hours} (chk_timer_unit)',
      );
    }
  }

  @override
  bool get hasValue => true;

  @override
  bool get hasTimer => true;

  @override
  List<Object?> get props => [value, unit];
}
