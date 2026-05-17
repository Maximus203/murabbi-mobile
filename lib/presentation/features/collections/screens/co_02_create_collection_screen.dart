import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/collection.dart';
import 'package:murabbi_mobile/domain/value_objects/collection_id.dart';
import 'package:murabbi_mobile/domain/value_objects/habit_id.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/presentation/features/collections/providers/collections_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// CO-02 — Formulaire de création d'une collection.
///
/// Champs V1 : nom (required), description (optional).
/// Champs reportés V2 : sélection d'habitudes depuis la liste, image de couverture.
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
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Le nom est requis.');
      return;
    }

    setState(() => _saving = true);
    try {
      final description = _descCtrl.text.trim();
      final collection = Collection(
        // L'id sera remplacé par l'UUID Supabase côté serveur lors du INSERT.
        // On passe un placeholder — le datasource n'utilise pas cet id lors
        // du createCollection (INSERT … RETURNING retourne le vrai UUID).
        id: CollectionId('placeholder-${DateTime.now().millisecondsSinceEpoch}'),
        name: NonEmptyString(name),
        description: NonEmptyString(
          description.isEmpty ? 'Collection sans description' : description,
        ),
        // Un placeholder est requis car le domaine exige habitIds non-vide.
        // Le Supabase INSERT retourne le vrai UUID (cf. supabase_collection_data_source.dart).
        habitIds: [HabitId('placeholder')],
        isSystem: false,
        isActive: false,
      );
      await ref
          .read(collectionsNotifierProvider.notifier)
          .create(collection);
      widget.onCreated();
    } catch (e, st) {
      appLog.e('Co02CreateCollectionScreen submit error', error: e, stackTrace: st);
      setState(() => _error = 'Une erreur est survenue. Réessaie.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Nouvelle collection',
        onBack: widget.onCancel,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInput(
              key: const Key('field_name'),
              controller: _nameCtrl,
              label: 'Nom',
              placeholder: 'Ex. Routine matinale',
            ),
            const SizedBox(height: AppSpacing.s4),
            AppInput(
              key: const Key('field_description'),
              controller: _descCtrl,
              label: 'Description',
              placeholder: "Décris l'objectif de cette collection (optionnel)",
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s3),
              Text(
                _error!,
                style: AppTypography.body.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: _saving ? 'Création...' : 'Créer',
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
