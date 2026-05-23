import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';

/// ST-02 — Profil (lecture seule depuis l'issue #168).
///
/// **Évolution #168** : avec la migration admin#125 (`pseudo_full` =
/// `pseudo#XXXX` immuable, suffixe CSPRNG, RPC `update_user_pseudo`
/// neutralisée côté serveur), il n'existe plus aucun chemin légitime
/// pour modifier son pseudo depuis le mobile. Cet écran devient une vue
/// de consultation : avatar, pseudo canonique, email verrouillé.
///
/// Le nom de classe `St02EditProfileScreen` est conservé pour ne pas
/// casser le routeur ; un futur PR pourra le renommer en
/// `St02ProfileScreen` une fois les call-sites migrés.
class St02EditProfileScreen extends ConsumerWidget {
  /// Retour vers ST-01.
  final VoidCallback onBack;

  /// Callback historique « profil enregistré » — plus jamais déclenché
  /// (lecture seule). Conservé pour compatibilité de signature.
  final VoidCallback onSaved;

  const St02EditProfileScreen({
    super.key,
    required this.onBack,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final displayPseudo = user?.displayPseudo ?? '—';
    final email = user?.email.value ?? '—';
    final initial = (user?.pseudo.value ?? '?').isEmpty
        ? '?'
        : (user?.pseudo.value ?? '?').characters.first.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(title: 'Profil', onBack: onBack),
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
                const SizedBox(height: AppSpacing.s4),
                Text(displayPseudo, style: AppTypography.h2),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          _ReadOnlyField(label: 'Pseudo (public)', value: displayPseudo),
          const SizedBox(height: AppSpacing.s2),
          Text(
            // Issue #168 — le suffixe `#XXXX` est tiré par CSPRNG côté
            // admin et figé pour la durée de vie du compte (admin#125).
            'Le pseudo et son suffixe sont définitifs et identifient ton '
            'compte de manière unique.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          _ReadOnlyField(label: 'Email', value: email),
          const SizedBox(height: AppSpacing.s2),
          Text(
            "L'email est verrouillé et ne peut pas être modifié.",
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Champ affiché en lecture seule (style cohérent avec `AppInput` désactivé
/// mais sans dépendre d'un `TextEditingController` — évite toute affordance
/// de saisie pour le lecteur d'écran).
class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderEmphasis),
          ),
          child: Text(
            value,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
