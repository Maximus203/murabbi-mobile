import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/settings/providers/edit_profile_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';

/// ST-02 — Modifier le profil (issue #7, Phase 6).
///
/// Avatar + lien "Changer la photo" (placeholder v2), champ pseudo public
/// éditable, email verrouillé. Sauvegarde avec feedback.
class St02EditProfileScreen extends ConsumerStatefulWidget {
  /// Retour vers ST-01.
  final VoidCallback onBack;

  /// Profil enregistré avec succès.
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
  final TextEditingController _pseudoCtrl = TextEditingController();
  String? _error;

  /// `true` une fois le champ pré-rempli avec le pseudo courant — évite
  /// d'écraser une saisie en cours si l'auth state se rafraîchit.
  bool _prefilled = false;

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    super.dispose();
  }

  bool get _isValidPseudo {
    final trimmed = _pseudoCtrl.text.trim();
    if (trimmed.isEmpty) return false;
    try {
      Pseudonym(trimmed);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final ok = await ref
        .read(editProfileNotifierProvider.notifier)
        .save(_pseudoCtrl.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
      widget.onSaved();
    } else {
      setState(() => _error = 'Impossible d\'enregistrer. Réessaie.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    // Pré-remplissage initial du pseudo dès que l'utilisateur est chargé.
    if (!_prefilled && user != null) {
      _pseudoCtrl.text = user.pseudo.value;
      _prefilled = true;
    }
    final saving = ref.watch(editProfileNotifierProvider).isLoading;
    final initial = (user?.pseudo.value ?? '?').isEmpty
        ? '?'
        : (user?.pseudo.value ?? '?').characters.first.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Modifier le profil',
        onBack: widget.onBack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s5),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
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
                Text(
                  'Changer la photo',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          AppInput(
            label: 'Pseudo (public)',
            placeholder: 'Ton pseudo',
            controller: _pseudoCtrl,
            maxLength: Pseudonym.maxLength,
            errorText: _error,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppInput(
            label: 'Email',
            controller: TextEditingController(text: user?.email.value ?? ''),
            enabled: false,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'L\'email est verrouillé et ne peut pas être modifié.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          AppButton(
            label: saving ? 'Enregistrement…' : 'Enregistrer',
            onPressed: (saving || !_isValidPseudo) ? null : _save,
          ),
        ],
      ),
    );
  }
}
