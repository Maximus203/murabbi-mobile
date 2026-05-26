import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/edit_profile_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// ST-02 — Mon profil.
///
/// Affiche les informations de profil selon le wireframe validé.
///
/// ## État des champs (Q-26 Option A)
///
/// - **Nom complet** : éditable — colonne `display_name TEXT` (migration
///   murabbi-admin requise). Bouton "Enregistrer" activé dès modification.
/// - **Email** : verrouillé Supabase Auth — toujours read-only.
/// - **Pseudonyme (classement)** : read-only per issue #168 (`pseudo_immutable_trigger`).
class St02EditProfileScreen extends ConsumerStatefulWidget {
  /// Retour vers ST-01.
  final VoidCallback onBack;

  /// Profil sauvegardé avec succès.
  final VoidCallback onSaved;

  const St02EditProfileScreen({
    super.key,
    required this.onBack,
    required this.onSaved,
  });

  @override
  ConsumerState<St02EditProfileScreen> createState() =>
      _St02EditProfileScreenState();
}

class _St02EditProfileScreenState extends ConsumerState<St02EditProfileScreen> {
  late final TextEditingController _displayNameCtrl;

  /// Valeur initiale au premier build avec `user != null`.
  /// Sert à détecter les modifications pour activer "Enregistrer".
  String? _initialDisplayName;
  bool _seeded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    final trimmed = _displayNameCtrl.text.trim();
    return trimmed != (_initialDisplayName ?? '');
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final ok = await ref
        .read(editProfileNotifierProvider.notifier)
        .saveDisplayName(_displayNameCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      widget.onSaved();
    } else {
      setState(
        () => _error = 'La sauvegarde a échoué. Réessaie plus tard.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final saving = ref.watch(editProfileNotifierProvider).isLoading;

    // Initialisation au premier build avec données utilisateur.
    if (!_seeded && user != null) {
      _seeded = true;
      _initialDisplayName = user.displayName;
      _displayNameCtrl.text = user.displayName ?? '';
    }

    final email = user?.email.value ?? '—';
    final initial = (user?.pseudo.value.isNotEmpty ?? false)
        ? user!.pseudo.value.characters.first.toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: 'Mon profil', onBack: widget.onBack),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          // ── Avatar ────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: AppComponentSize.avatarLg,
                  height: AppComponentSize.avatarLg,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: AppTypography.display.copyWith(
                      color: AppColors.bgSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                // Q-26 : feature photo non déployée — no-op.
                GestureDetector(
                  onTap: () =>
                      appLog.d('ST-02 : Modifier la photo — Q-26 pending'),
                  child: Text(
                    'Modifier la photo',
                    style: AppTypography.body.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),

          // ── Nom complet (Q-26 Option A — éditable) ────────────────────
          const _FieldLabel(label: 'Nom complet'),
          const SizedBox(height: AppSpacing.s1),
          AppInput(
            placeholder: 'Ton nom complet',
            controller: _displayNameCtrl,
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.s4),

          // ── Email (verrouillé Supabase Auth) ──────────────────────────
          const _FieldLabel(label: 'Email'),
          const SizedBox(height: AppSpacing.s1),
          _ReadOnlyField(value: email, hint: 'Email', showLock: true),
          const SizedBox(height: AppSpacing.s4),

          // ── Pseudonyme classement (Q-26 — issue #168) ─────────────────
          const _FieldLabel(label: 'Pseudonyme (classement)'),
          const SizedBox(height: AppSpacing.s1),
          _ReadOnlyField(
            value: user?.pseudo.value ?? '—',
            hint: 'Pseudonyme',
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            'Apparaîtra publiquement sur le classement.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),

          // ── Enregistrer (activé dès que Nom complet modifié) ──────────
          AppButton(
            label: saving ? 'Enregistrement…' : 'Enregistrer',
            variant: AppButtonVariant.primary,
            onPressed: (saving || !_canSave) ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

/// Label de champ — style `label` secondaire.
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
    );
  }
}

/// Champ en lecture seule visuellement cohérent avec AppInput désactivé.
/// [showLock] ajoute l'icône cadenas (champ Email).
class _ReadOnlyField extends StatelessWidget {
  final String value;
  final String hint;
  final bool showLock;

  const _ReadOnlyField({
    required this.value,
    required this.hint,
    this.showLock = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppBorderWidth.thin,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (showLock)
            const Icon(
              LucideIcons.lock,
              size: AppIconSize.sm,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }
}
