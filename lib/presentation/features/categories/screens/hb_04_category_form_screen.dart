import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/category.dart';
import 'package:murabbi_mobile/domain/value_objects/category_id.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/categories_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/providers/category_form_notifier.dart';
import 'package:murabbi_mobile/presentation/features/categories/widgets/category_tile.dart';
import 'package:murabbi_mobile/presentation/features/categories/widgets/color_picker_grid.dart';
import 'package:murabbi_mobile/presentation/features/categories/widgets/icon_selector_grid.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_dialog.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// HB-04 — Formulaire de création / édition d'une catégorie.
///
/// En mode édition ([initialCategory] non-null), les champs sont pré-remplis
/// et un bouton « Supprimer la catégorie » apparaît (désactivé si la
/// catégorie est système).
class Hb04CategoryFormScreen extends ConsumerStatefulWidget {
  /// Catégorie à éditer — `null` en mode création.
  final Category? initialCategory;

  /// Fermeture après enregistrement ou suppression réussis.
  final VoidCallback onDone;

  /// Annulation (bouton retour).
  final VoidCallback onCancel;

  const Hb04CategoryFormScreen({
    super.key,
    this.initialCategory,
    required this.onDone,
    required this.onCancel,
  });

  @override
  ConsumerState<Hb04CategoryFormScreen> createState() =>
      _Hb04CategoryFormScreenState();
}

class _Hb04CategoryFormScreenState
    extends ConsumerState<Hb04CategoryFormScreen> {
  late final TextEditingController _nameController;
  bool _saving = false;

  bool get _isEdit => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategory?.name.value ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = categoryFormNotifierProvider(widget.initialCategory);
    final form = ref.watch(formProvider);
    final notifier = ref.read(formProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: _isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie',
        onBack: widget.onCancel,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          // ── Preview temps réel ────────────────────────────────────────
          const Text('APERÇU', style: AppTypography.label),
          const SizedBox(height: AppSpacing.s2),
          CategoryTile(
            name: form.name.trim().isEmpty ? 'Nom de la catégorie' : form.name,
            color: form.color,
            icon: form.icon,
          ),
          const SizedBox(height: AppSpacing.s5),

          // ── Nom ───────────────────────────────────────────────────────
          AppInput(
            label: 'Nom',
            placeholder: 'Ex. Lecture, Méditation…',
            controller: _nameController,
            maxLength: 32,
            onChanged: notifier.setName,
          ),
          const SizedBox(height: AppSpacing.s5),

          // ── Couleur ───────────────────────────────────────────────────
          const Text('COULEUR', style: AppTypography.label),
          const SizedBox(height: AppSpacing.s3),
          ColorPickerGrid(selected: form.color, onSelected: notifier.setColor),
          const SizedBox(height: AppSpacing.s5),

          // ── Icône ─────────────────────────────────────────────────────
          const Text('ICÔNE', style: AppTypography.label),
          const SizedBox(height: AppSpacing.s3),
          IconSelectorGrid(
            selected: form.icon,
            accentColor: form.color,
            onSelected: notifier.setIcon,
          ),
          const SizedBox(height: AppSpacing.s5),

          // ── Enregistrer ───────────────────────────────────────────────
          AppButton(
            label: 'Enregistrer',
            onPressed: form.canSubmit && !_saving ? () => _save(form) : null,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: AppBorderWidth.indicatorStroke,
                      color: AppColors.bgSurface,
                    ),
                  )
                : null,
          ),

          // ── Supprimer (mode édition uniquement) ───────────────────────
          if (_isEdit) ...[
            const SizedBox(height: AppSpacing.s3),
            AppButton(
              label: 'Supprimer la catégorie',
              variant: AppButtonVariant.destructive,
              onPressed: (widget.initialCategory!.isSystem || _saving)
                  ? null
                  : _delete,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(CategoryFormState form) async {
    setState(() => _saving = true);
    final notifier = ref.read(categoriesNotifierProvider.notifier);
    try {
      final category = Category(
        // En édition on conserve l'id existant ; en création le repo
        // attribue l'id définitif — on passe un id temporaire stable.
        id:
            widget.initialCategory?.id ??
            CategoryId('cat-${DateTime.now().microsecondsSinceEpoch}'),
        name: NonEmptyString(form.name),
        color: HexColor(_colorToHex(form.color)),
        icon: form.icon,
        isSystem: widget.initialCategory?.isSystem ?? false,
      );
      if (_isEdit) {
        await notifier.updateCategory(category);
      } else {
        await notifier.createCategory(category);
      }
      if (!mounted) return;
      widget.onDone();
    } catch (e, st) {
      appLog.e('Hb04 save category failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l’enregistrement.')),
      );
    }
  }

  Future<void> _delete() async {
    final category = widget.initialCategory!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: 'Supprimer la catégorie ?',
        body: '« ${category.name.value} » sera définitivement supprimée.',
        confirmLabel: 'Supprimer',
        isDangerous: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .deleteCategory(category.id);
      if (!mounted) return;
      widget.onDone();
    } catch (e, st) {
      appLog.e('Hb04 delete category failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Échec de la suppression.')));
    }
  }
}

/// Convertit un [Color] en token `#RRGGBB` attendu par [HexColor].
String _colorToHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
