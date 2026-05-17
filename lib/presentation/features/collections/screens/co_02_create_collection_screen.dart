import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habits_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// CO-02 — Création d'une collection (issue #6, Phase 5).
///
/// Formulaire : titre, description, sélection multiple d'habitudes.
/// La collection nécessite au moins une habitude (invariant domaine).
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

    // L'id réel est attribué par Supabase ; on fournit un placeholder
    // remplacé par la row persistée côté repository.
    final collection = Collection(
      id: CollectionId('pending'),
      name: NonEmptyString(_nameController.text),
      description: NonEmptyString(_descController.text),
      habitIds: _selected.map(HabitId.new).toList(),
      isSystem: false,
      isActive: false,
    );

    await ref.read(collectionsNotifierProvider.notifier).create(collection);
    if (mounted) widget.onCreated();
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsNotifierProvider);
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
            Text(
              'HABITUDES'.toUpperCase(),
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
