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

/// Map statique nom kebab-case → IconData pour les icônes Lucide proposées
/// dans CO-02 (Q-23). Le nom est persisté en base ; l'icône est résolue
/// côté client à l'affichage.
const Map<String, IconData> _kCollectionIconMap = {
  'layers': LucideIcons.layers,
  'star': LucideIcons.star,
  'flame': LucideIcons.flame,
  'target': LucideIcons.target,
  'zap': LucideIcons.zap,
  'heart': LucideIcons.heart,
  'shield': LucideIcons.shield,
  'trophy': LucideIcons.trophy,
  'compass': LucideIcons.compass,
  'sparkles': LucideIcons.sparkles,
};

/// CO-02 — Création d'une collection (issue #6, Phase 5 / Q-23).
///
/// Formulaire : titre, description, catégorie principale (optionnel),
/// icône (optionnel), sélection multiple d'habitudes (obligatoire).
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
  CategoryId? _selectedCategoryId;
  String? _selectedIcon;
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
      name: NonEmptyString(_nameController.text.trim()),
      description: NonEmptyString(_descController.text.trim()),
      habitIds: _selected.map(HabitId.new).toList(),
      isSystem: false,
      isActive: false,
      primaryCategoryId: _selectedCategoryId,
      icon: _selectedIcon,
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

            // ── Catégorie principale (optionnel) ──────────────────────────
            Text(
              'CATÉGORIE PRINCIPALE',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            categories.when(
              loading: () => const SizedBox(
                height: 36,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (cats) => _CategoryPicker(
                categories: cats,
                selectedId: _selectedCategoryId,
                onToggle: (id) => setState(() {
                  _selectedCategoryId =
                      _selectedCategoryId == id ? null : id;
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Icône (optionnel) ─────────────────────────────────────────
            Text(
              'ICÔNE',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            _IconGrid(
              selectedIcon: _selectedIcon,
              onToggle: (name) => setState(() {
                _selectedIcon = _selectedIcon == name ? null : name;
              }),
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

class _CategoryPicker extends StatelessWidget {
  final List<Category> categories;
  final CategoryId? selectedId;
  final void Function(CategoryId) onToggle;

  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: categories.map((cat) {
        final isSelected = selectedId == cat.id;
        return ChoiceChip(
          label: Text(cat.name.value),
          selected: isSelected,
          onSelected: (_) => onToggle(cat.id),
          selectedColor: AppColors.accent,
          labelStyle: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.bgSurface : AppColors.textPrimary,
          ),
          backgroundColor: AppColors.bgSurface,
          side: BorderSide(
            color: isSelected ? AppColors.accent : AppColors.borderDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.s2),
          ),
        );
      }).toList(),
    );
  }
}

class _IconGrid extends StatelessWidget {
  final String? selectedIcon;
  final void Function(String) onToggle;

  const _IconGrid({required this.selectedIcon, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: _kCollectionIconMap.entries.map((entry) {
        final isSelected = selectedIcon == entry.key;
        return GestureDetector(
          onTap: () => onToggle(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppSpacing.s2),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.borderDefault,
              ),
            ),
            child: Icon(
              lu(entry.value),
              size: 24,
              color:
                  isSelected ? AppColors.bgSurface : AppColors.textSecondary,
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
                  lu(isSelected ? LucideIcons.squareCheck : LucideIcons.square),
                  size: 20,
                  color: isSelected ? AppColors.accent : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(h.name.value, style: AppTypography.body),
                ),
                Text(
                  '${h.points.value} pts',
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
