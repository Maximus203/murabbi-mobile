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

/// HA-02 — Formulaire de création / édition d'habitude (slice 3.D + #152).
///
/// Deux modes :
/// - **Création** : [initialHabit] == null. Champs vides, chips jours non
///   pré-sélectionnés (#141), bouton "Créer l'habitude".
/// - **Édition** : [initialHabit] fourni. Champs pré-remplis, bouton
///   "Enregistrer les modifications", appel à [updateHabitUseCaseProvider].
///
/// Bugs corrigés (#152) : #139 (stepper clamp), #141 (chips jours),
/// #142 (erreur effacée à la frappe), #143 (erreur inline sous NOM),
/// #127 (labels fréquence FR), #144 (feedback succès).
///
/// Reporté V2 : sous-tâches, time range, target chiffré, timer. Cf.
/// `spec v1.5` et ADR-008.
class Ha02CreateHabitScreen extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  final VoidCallback onCancel;

  /// Si non-null, l'écran passe en mode édition et pré-remplit les champs.
  final Habit? initialHabit;

  const Ha02CreateHabitScreen({
    super.key,
    required this.onCreated,
    required this.onCancel,
    this.initialHabit,
  });

  /// True si l'écran est en mode édition.
  bool get isEditMode => initialHabit != null;

  @override
  ConsumerState<Ha02CreateHabitScreen> createState() =>
      _Ha02CreateHabitScreenState();
}

class _Ha02CreateHabitScreenState extends ConsumerState<Ha02CreateHabitScreen> {
  /// Nom max — borne UI (#152, validation inline).
  static const int _nameMaxLength = 64;

  late final TextEditingController _nameCtrl;
  CategoryId? _categoryId;
  late HabitFrequencyType _frequencyType;
  late int _perDayFrequency;

  /// Jours actifs sélectionnés. #141 : `{}` en création, `habit.activeDays`
  /// en édition (mode "jours précis").
  late final Set<int> _activeDays;
  late int _points;
  bool _saving = false;

  /// Indique si l'utilisateur a tenté un premier submit — active la validation
  /// inline (#143).
  bool _submitted = false;

  /// Erreur globale (réseau / auth) — distincte des erreurs inline.
  String? _globalError;

  @override
  void initState() {
    super.initState();
    final h = widget.initialHabit;
    _nameCtrl = TextEditingController(text: h?.name.value ?? '');
    _categoryId = h?.categoryId;
    _frequencyType = h?.frequencyType ?? HabitFrequencyType.daily;
    _perDayFrequency = h?.frequencyType == HabitFrequencyType.perDay
        ? h!.frequency
        : 1;
    // #141 : pas de pré-sélection en création. En édition mode "jours précis",
    // on reprend les jours de l'habitude.
    _activeDays = h != null && h.frequencyType == HabitFrequencyType.weekly
        ? Set.of(h.activeDays)
        : <int>{};
    _points = h?.points.value ?? 3;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Erreur inline du champ Nom — affichée uniquement après le 1er submit (#143).
  String? get _nameError {
    if (!_submitted) return null;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return 'Le nom est requis.';
    if (name.length > _nameMaxLength) {
      return 'Le nom ne doit pas dépasser $_nameMaxLength caractères.';
    }
    return null;
  }

  /// Erreur inline des jours — affichée après le 1er submit si la fréquence
  /// est "jours précis" et qu'aucun jour n'est sélectionné (#152).
  String? get _daysError {
    if (!_submitted) return null;
    if (_frequencyType == HabitFrequencyType.weekly && _activeDays.isEmpty) {
      return 'Sélectionne au moins un jour.';
    }
    return null;
  }

  Future<void> _submit(List<Category> categories) async {
    setState(() {
      _submitted = true;
      _globalError = null;
    });

    // Validation inline — stoppe si une erreur est présente.
    if (_nameError != null || _daysError != null) return;

    final name = _nameCtrl.text.trim();
    final catId = _categoryId ?? categories.first.id;
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      setState(() => _globalError = 'Tu dois être connecté.');
      return;
    }

    // Les habitudes "daily" / "perDay" couvrent tous les jours ; "weekly"
    // utilise la sélection utilisateur.
    final activeDays = _frequencyType == HabitFrequencyType.weekly
        ? Set.of(_activeDays)
        : {1, 2, 3, 4, 5, 6, 7};

    setState(() => _saving = true);
    try {
      final habit = Habit(
        id:
            widget.initialHabit?.id ??
            HabitId('habit-${DateTime.now().microsecondsSinceEpoch}'),
        name: NonEmptyString(name),
        categoryId: catId,
        frequencyType: _frequencyType,
        frequency: _frequencyType == HabitFrequencyType.perDay
            ? _perDayFrequency
            : 1,
        activeDays: activeDays,
        points: HabitPoints(_points),
        isSystem: false,
      );

      if (widget.isEditMode) {
        await ref.read(updateHabitUseCaseProvider).call(habit);
      } else {
        await ref
            .read(createHabitUseCaseProvider)
            .call(userId: user.id, habit: habit);
      }
      await ref.read(habitsNotifierProvider.notifier).refresh();
      if (!mounted) return;
      // #144 : feedback succès avant de quitter l'écran.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode ? 'Habitude mise à jour.' : 'Habitude créée.',
          ),
        ),
      );
      widget.onCreated();
    } catch (e, stackTrace) {
      appLog.e(
        'Ha02CreateHabitScreen submit failed',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _saving = false;
        _globalError = widget.isEditMode
            ? "Impossible de mettre à jour l'habitude. Réessaie dans un instant."
            : "Impossible de créer l'habitude. Réessaie dans un instant.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: widget.isEditMode ? "Modifier l'habitude" : 'Nouvelle habitude',
        onBack: widget.onCancel,
      ),
      body: categoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidth.indicatorStroke,
          ),
        ),
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
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        // ── Nom — validation inline (#142 #143) ─────────────────────
        AppInput(
          label: 'Nom',
          placeholder: 'ex. Lecture Coran',
          controller: _nameCtrl,
          errorText: _nameError,
          maxLength: _nameMaxLength,
          onChanged: (_) {
            // #142 : efface l'erreur dès que l'utilisateur tape.
            if (_submitted) setState(() {});
          },
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Catégorie — AppChip (#86) ──────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Catégorie', style: AppTypography.h3),
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
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _hexToColor(c.color.value),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
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
                              ? LucideIcons.circleCheck
                              : LucideIcons.circle,
                          size: 20,
                          color: _frequencyType == t
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: Text(
                            _frequencyOptionLabel(t),
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
                      tooltip: 'Diminuer la fréquence',
                      // #139 : clamp physique — désactivé à la borne min.
                      onPressed: _perDayFrequency > 1
                          ? () => setState(() => _perDayFrequency--)
                          : null,
                      icon: const Icon(LucideIcons.minus, size: 16),
                    ),
                    Text('$_perDayFrequency', style: AppTypography.h3),
                    IconButton(
                      tooltip: 'Augmenter la fréquence',
                      onPressed: _perDayFrequency < 10
                          ? () => setState(() => _perDayFrequency++)
                          : null,
                      icon: const Icon(LucideIcons.plus, size: 16),
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
                            _activeDays.remove(d);
                          } else {
                            _activeDays.add(d);
                          }
                        }),
                      ),
                  ],
                ),
                // Erreur inline jours (#152).
                if (_daysError != null) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    _daysError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Points / Difficulté — #139 clamp [1..10] ───────────────
        AppCard(
          child: Row(
            children: [
              const Text('Difficulté', style: AppTypography.h3),
              const Spacer(),
              IconButton(
                tooltip: 'Diminuer les points',
                onPressed: _points > HabitPoints.min
                    ? () => setState(() => _points--)
                    : null,
                icon: const Icon(LucideIcons.minus, size: 16),
              ),
              Text(
                '$_points pt${_points > 1 ? 's' : ''}',
                style: AppTypography.body.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'Augmenter les points',
                onPressed: _points < HabitPoints.max
                    ? () => setState(() => _points++)
                    : null,
                icon: const Icon(LucideIcons.plus, size: 16),
              ),
            ],
          ),
        ),

        // ── Erreur globale (réseau / auth) ─────────────────────────
        if (_globalError != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.danger),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Text(
              _globalError!,
              style: AppTypography.body.copyWith(color: AppColors.danger),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.s6),

        // ── Bouton submit ──────────────────────────────────────────
        AppButton(
          label: widget.isEditMode
              ? 'Enregistrer les modifications'
              : "Créer l'habitude",
          onPressed: _saving ? null : () => _submit(categories),
          isLoading: _saving,
        ),
        const SizedBox(height: AppSpacing.s6),
      ],
    );
  }

  /// Libellé de l'option de récurrence dans le sélecteur.
  static String _frequencyOptionLabel(HabitFrequencyType t) {
    switch (t) {
      case HabitFrequencyType.daily:
        return 'Tous les jours';
      case HabitFrequencyType.perDay:
        return 'Plusieurs fois par jour';
      case HabitFrequencyType.weekly:
        return 'Jours précis de la semaine';
      case HabitFrequencyType.perWeek:
        return 'Plusieurs fois par semaine';
      case HabitFrequencyType.monthly:
        return 'Une fois par mois';
      case HabitFrequencyType.custom:
        return 'Personnalisée';
    }
  }
}

/// Convertit un token couleur au format `#RRGGBB` (DS — HexColor) en [Color].
Color _hexToColor(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
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
    final label = _labels[day - 1];
    // D-28 (issue #105) : zone de tap ≥ 44×44dp (P-A11Y).
    // Le visuel reste 36×36, mais la hitbox est étendue à 44×44 via SizedBox.
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: SizedBox(
        width: kMinInteractiveDimension,
        height: kMinInteractiveDimension,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Center(
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
              child: ExcludeSemantics(
                // D-33 : le texte du chip est purement décoratif — la Semantics
                // parente porte déjà le label du jour.
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: selected
                        ? AppColors.bgSurface
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
