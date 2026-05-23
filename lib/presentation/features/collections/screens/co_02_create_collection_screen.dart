import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/icon_utils.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
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
/// Formulaire : titre, description, catégorie principale (Q-23),
/// icône (Q-23) et sélection multiple d'habitudes (Q-24).
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
    final habits = ref.watch(habitsNotifierProvider);
    final categories = ref.watch(categoriesNotifierProvider);
    final isSaving = ref.watch(collectionsNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s4,
            AppSpacing.s5,
            AppSpacing.s8,
          ),
          children: [
            AppHeader.back(
              title: 'Nouvelle collection',
              onBack: widget.onCancel,
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Titre ─────────────────────────────────────────────────────
            AppInput(
              label: 'Titre',
              placeholder: 'Routine du matin',
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              errorText: _submitted && _nameController.text.trim().isEmpty
                  ? 'Titre requis'
                  : null,
            ),
            const SizedBox(height: AppSpacing.s4),

            // ── Description ───────────────────────────────────────────────
            AppInput(
              label: 'Description',
              placeholder: 'À quoi sert cette collection ?',
              controller: _descController,
              onChanged: (_) => setState(() {}),
              errorText: _submitted && _descController.text.trim().isEmpty
                  ? 'Description requise'
                  : null,
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Catégorie principale (Q-23) ───────────────────────────────
            const Text('CATÉGORIE PRINCIPALE', style: AppTypography.label),
            const SizedBox(height: AppSpacing.s3),
            categories.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (cats) => Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: cats.map((cat) {
                  final isSelected = _primaryCategoryId == cat.id.value;
                  return ChoiceChip(
                    label: Text(cat.name.value),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      _primaryCategoryId = isSelected ? null : cat.id.value;
                    }),
                    selectedColor: AppColors.accent,
                    labelStyle: AppTypography.caption.copyWith(
                      color: isSelected
                          ? AppColors.bgSurface
                          : AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.bgInput,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Icône (Q-23) ──────────────────────────────────────────────
            const Text('ICÔNE', style: AppTypography.label),
            const SizedBox(height: AppSpacing.s3),
            _CollectionIconPicker(
              selected: _icon,
              onSelected: (name) =>
                  setState(() => _icon = _icon == name ? null : name),
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Habitudes ─────────────────────────────────────────────────
            Text(
              'HABITUDES',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            habits.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s4),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => Text(
                'Impossible de charger les habitudes.',
                style: AppTypography.body.copyWith(color: AppColors.danger),
              ),
              data: (list) => _HabitPicker(
                habits: list,
                selected: _selected,
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
            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: 'Créer la collection',
              onPressed: isSaving ? null : _submit,
            ),
          ],
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
            width: 52,
            height: 52,
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

class _HabitPicker extends StatelessWidget {
  final List<Habit> habits;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _HabitPicker({
    required this.habits,
    required this.selected,
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
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s2),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.s3),
            onTap: () => onToggle(id),
            child: Row(
              children: [
                Icon(
                  isSelected ? LucideIcons.squareCheck : LucideIcons.square,
                  size: 20,
                  color: isSelected ? AppColors.accent : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(child: Text(h.name.value, style: AppTypography.body)),
                // #163 : points nullable — on masque si null.
                if (h.points != null)
                  Text(
                    '${h.points!.value} pts',
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
