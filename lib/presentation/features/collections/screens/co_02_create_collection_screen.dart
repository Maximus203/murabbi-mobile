import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// Icônes Lucide proposées pour une collection (CO-02, Q-23).
const List<String> kCollectionIconNames = [
  'sun',
  'moon-star',
  'book-open',
  'heart-pulse',
  'dumbbell',
  'brain',
  'leaf',
  'star',
  'layout-grid',
  'flame',
];

/// Lookup statique nom kebab-case → IconData Lucide.
///
/// LucideIcons n'est pas une enum — on ne peut pas utiliser `.values.byName()`.
/// Cette map couvre exactement [kCollectionIconNames].
final Map<String, IconData> _kCollectionIconMap = {
  'sun': LucideIcons.sun,
  'moon-star': LucideIcons.moonStar,
  'book-open': LucideIcons.bookOpen,
  'heart-pulse': LucideIcons.heartPulse,
  'dumbbell': LucideIcons.dumbbell,
  'brain': LucideIcons.brain,
  'leaf': LucideIcons.leaf,
  'star': LucideIcons.star,
  'layout-grid': LucideIcons.layoutGrid,
  'flame': LucideIcons.flame,
};

/// CO-02 — Création d'une collection (issue #6, Phase 5).
///
/// Formulaire : titre, description, catégorie principale (chips colorés),
/// icône et sélection multiple d'habitudes.
///
/// Footer sticky : compteur de sélection + pts/jour + bouton "Créer".
class Co02CreateCollectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  final VoidCallback onCancel;

  const Co02CreateCollectionScreen({
    super.key,
    required this.onCreated,
    required this.onCancel,
  });

  @override
  ConsumerState<Co02CreateCollectionScreen> createState() =>
      _Co02CreateCollectionScreenState();
}

class _Co02CreateCollectionScreenState
    extends ConsumerState<Co02CreateCollectionScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _selected = <String>{};
  String? _primaryCategoryId;
  String? _icon;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty &&
      _selected.isNotEmpty;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_isValid) return;

    final collection = Collection(
      id: CollectionId('pending'),
      name: NonEmptyString(_nameController.text),
      description: NonEmptyString(_descController.text),
      habitIds: _selected.map(HabitId.new).toList(),
      isSystem: false,
      isActive: false,
      primaryCategoryId: _primaryCategoryId != null
          ? CategoryId(_primaryCategoryId!)
          : null,
      icon: _icon,
    );

    await ref.read(collectionsNotifierProvider.notifier).create(collection);
    if (mounted) widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsNotifierProvider);
    final allHabits = habitsAsync.valueOrNull ?? [];
    final categories = ref.watch(categoriesNotifierProvider);
    final allCategories = categories.valueOrNull ?? [];
    final isSaving = ref.watch(collectionsNotifierProvider).isLoading;

    // Calcul pts/jour des habitudes sélectionnées.
    final selectedPts = allHabits
        .where((h) => _selected.contains(h.id.value))
        .fold(0, (sum, h) => sum + (h.points?.value ?? 0));

    // Map catégorie pour lookup dans le picker d'habitudes.
    final categoryMap = <CategoryId, Category>{
      for (final c in allCategories) c.id: c,
    };

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Nouvelle collection',
        onBack: widget.onCancel,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s4,
            AppSpacing.s5,
            AppSpacing.s4,
          ),
          children: [
            // ── Titre ───────────────────────────────────────────────────
            AppInput(
              key: const Key('field_name'),
              label: 'Titre',
              placeholder: 'Ex. Routine du matin',
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              errorText: _submitted && _nameController.text.trim().isEmpty
                  ? 'Titre requis'
                  : null,
            ),
            const SizedBox(height: AppSpacing.s4),

            // ── Description ─────────────────────────────────────────────
            AppInput(
              key: const Key('field_description'),
              label: 'Description',
              placeholder:
                  'Quelques mots pour rappeler l\'intention de cette collection.',
              controller: _descController,
              onChanged: (_) => setState(() {}),
              errorText: _submitted && _descController.text.trim().isEmpty
                  ? 'Description requise'
                  : null,
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Catégorie principale ─────────────────────────────────────
            Text(
              'CATÉGORIE PRINCIPALE',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: allCategories.map((cat) {
                final isSelected = _primaryCategoryId == cat.id.value;
                final catColor = _colorFromHex(cat.color);
                return GestureDetector(
                  onTap: () => setState(() {
                    _primaryCategoryId =
                        isSelected ? null : cat.id.value;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s3,
                      vertical: AppSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor : AppColors.bgInput,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: AppColors.borderEmphasis,
                              width: AppBorderWidth.thin,
                            ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.bgSurface
                                : catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          cat.name.value,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.bgSurface
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Icône ────────────────────────────────────────────────────
            Text(
              'ICÔNE',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            _CollectionIconPicker(
              selected: _icon,
              onSelected: (name) =>
                  setState(() => _icon = _icon == name ? null : name),
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Habitudes à inclure ──────────────────────────────────────
            Text(
              'HABITUDES À INCLURE',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            habitsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s4),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, st) => Text(
                'Impossible de charger les habitudes.',
                style: AppTypography.body.copyWith(color: AppColors.danger),
              ),
              data: (list) => _HabitPicker(
                habits: list,
                selected: _selected,
                categoryMap: categoryMap,
                onToggle: (id) => setState(() {
                  _selected.contains(id)
                      ? _selected.remove(id)
                      : _selected.add(id);
                }),
              ),
            ),
            if (_submitted && _selected.isEmpty) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Sélectionne au moins une habitude.',
                style: AppTypography.caption.copyWith(color: AppColors.danger),
              ),
            ],
            // Espace pour que le footer ne masque pas le bas de la liste.
            const SizedBox(height: AppSpacing.s8),
          ],
        ),
      ),

      // ── Footer sticky : compteur + bouton ─────────────────────────────
      bottomNavigationBar: SafeArea(
        top: false,
        child: _CreateFooter(
          selectedCount: _selected.length,
          ptsPerDay: selectedPts,
          isSaving: isSaving,
          isValid: _isValid,
          onSubmit: _submit,
        ),
      ),
    );
  }
}

/// Grille de sélection d'icône pour une collection (Q-23).
class _CollectionIconPicker extends StatelessWidget {
  final String? selected;
  final void Function(String) onSelected;

  const _CollectionIconPicker({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: kCollectionIconNames.map((name) {
        final isSelected = selected == name;
        return GestureDetector(
          onTap: () => onSelected(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: AppComponentSize.iconSelectorCell,
            height: AppComponentSize.iconSelectorCell,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.bgInput,
              borderRadius: BorderRadius.circular(AppSpacing.s3),
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.borderEmphasis),
            ),
            child: Icon(
              lu(_kCollectionIconMap[name] ?? LucideIcons.layoutGrid),
              size: 22,
              color: isSelected ? AppColors.bgSurface : AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Picker d'habitudes avec nom, catégorie et fréquence (CO-02).
class _HabitPicker extends StatelessWidget {
  final List<Habit> habits;
  final Set<String> selected;
  final Map<CategoryId, Category> categoryMap;
  final void Function(String) onToggle;

  const _HabitPicker({
    required this.habits,
    required this.selected,
    required this.categoryMap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return Text(
        'Crée d\'abord des habitudes pour les regrouper.',
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: habits.map((h) {
        final id = h.id.value;
        final isSelected = selected.contains(id);
        final category = categoryMap[h.categoryId];
        final catName = category?.name.value ?? '';
        final freqLabel = _frequencyLabel(h);
        final subtitle = catName.isNotEmpty
            ? '$catName · $freqLabel'
            : freqLabel;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.s3),
            onTap: () => onToggle(id),
            child: Row(
              children: [
                Icon(
                  isSelected ? LucideIcons.squareCheck : LucideIcons.square,
                  size: AppIconSize.rg,
                  color: isSelected ? AppColors.accent : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name.value, style: AppTypography.body),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (h.points != null)
                  Text(
                    '+${h.points!.value} pts',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Footer sticky CO-02 : compteur de sélection + pts/jour + bouton Créer.
class _CreateFooter extends StatelessWidget {
  final int selectedCount;
  final int ptsPerDay;
  final bool isSaving;
  final bool isValid;
  final VoidCallback onSubmit;

  const _CreateFooter({
    required this.selectedCount,
    required this.ptsPerDay,
    required this.isSaving,
    required this.isValid,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        AppSpacing.s5,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderDefault,
            width: AppBorderWidth.thin,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s3),
              child: Text(
                '$selectedCount habitude${selectedCount > 1 ? "s" : ""} '
                'sélectionnée${selectedCount > 1 ? "s" : ""}'
                '${ptsPerDay > 0 ? " • +$ptsPerDay pts/jour" : ""}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          AppButton(
            label: 'Créer la collection',
            onPressed: isSaving ? null : onSubmit,
            isLoading: isSaving,
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Convertit un [HexColor] en [Color] Flutter.
Color _colorFromHex(HexColor hex) {
  final s = hex.value.replaceFirst('#', '');
  return Color(int.parse(s, radix: 16) | 0xFF000000);
}

/// Libellé de fréquence français.
String _frequencyLabel(Habit h) {
  return switch (h.frequencyType) {
    HabitFrequencyType.daily => 'Quotidien',
    HabitFrequencyType.perDay => '${h.frequency}×/jour',
    HabitFrequencyType.perWeek => '${h.frequency}×/sem.',
    HabitFrequencyType.weekly => '${h.activeDays.length}j/sem.',
    HabitFrequencyType.monthly => 'Mensuel',
    HabitFrequencyType.custom => 'Personnalisé',
  };
}
