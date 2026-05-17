import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/location_service_provider.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_settings_form_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_settings_form_state.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';
import 'package:murabbi_mobile/presentation/widgets/app_snackbar.dart';
import 'package:murabbi_mobile/presentation/widgets/app_toggle.dart';
import 'package:murabbi_mobile/services/location/location_service.dart';

/// SA-02 — Écran de réglages des prières (slice 3.C.3).
///
/// Saisie manuelle des coordonnées (lat/lng), méthode de calcul, école
/// juridique, et règle hautes latitudes (visible si |lat| > 48°).
///
/// Bouton "Ma position GPS" (geolocator + ADR-014, slice 3.C.3 follow-up
/// PR #44) : pré-remplit lat/lng via le service de localisation, avec
/// gestion exhaustive des cas d'erreur (permission, GPS désactivé, etc.).
class Sa02PrayerSettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  final VoidCallback onBack;

  const Sa02PrayerSettingsScreen({
    super.key,
    required this.onSaved,
    required this.onBack,
  });

  @override
  ConsumerState<Sa02PrayerSettingsScreen> createState() =>
      _Sa02PrayerSettingsScreenState();
}

class _Sa02PrayerSettingsScreenState
    extends ConsumerState<Sa02PrayerSettingsScreen> {
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(prayerSettingsFormNotifierProvider.notifier).loadInitial();
      if (!mounted) return;
      final state = ref.read(prayerSettingsFormNotifierProvider);
      if (state.latitude != null) _latCtrl.text = state.latitude!.toString();
      if (state.longitude != null) _lngCtrl.text = state.longitude!.toString();
    });
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUsePosition() async {
    setState(() => _isLocating = true);
    final svc = ref.read(locationServiceProvider);
    final result = await svc.getCurrentPosition();
    if (!mounted) return;
    setState(() => _isLocating = false);

    switch (result) {
      case LocationSuccess(:final latitude, :final longitude):
        final notifier = ref.read(prayerSettingsFormNotifierProvider.notifier);
        _latCtrl.text = latitude.toStringAsFixed(6);
        _lngCtrl.text = longitude.toStringAsFixed(6);
        notifier
          ..setLatitude(latitude)
          ..setLongitude(longitude);
      case LocationPermissionDenied(:final deniedForever):
        _showSnack(
          deniedForever
              ? 'Autorise la localisation dans les réglages.'
              : 'Permission localisation refusée.',
          actionLabel: deniedForever ? 'Réglages' : null,
          onAction: deniedForever ? svc.openAppSettings : null,
        );
      case LocationServiceDisabled():
        _showSnack(
          'Active la localisation système.',
          actionLabel: 'Activer',
          onAction: svc.openLocationSettings,
        );
      case LocationUnknownError(:final message):
        // Audit TL PR #44 : pas de message technique brut à l'utilisateur.
        // Détail loggé pour debug, snackbar avec libellé canonique FR.
        appLog.e('GPS getCurrentPosition unknown error', error: message);
        _showSnack('Erreur lors de la localisation. Réessaie dans un instant.');
    }
  }

  void _showSnack(
    String message, {
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    // #146 : SnackBar thémée DS au lieu du ScaffoldMessenger brut.
    showAppSnackBar(
      context,
      message,
      actionLabel: actionLabel,
      onAction: (actionLabel != null && onAction != null)
          ? () => onAction()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerSettingsFormNotifierProvider);
    final notifier = ref.read(prayerSettingsFormNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppHeader.back(
        title: 'Réglages des prières',
        onBack: widget.onBack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          _LocationSection(
            latCtrl: _latCtrl,
            lngCtrl: _lngCtrl,
            onLatChanged: (s) => notifier.setLatitude(double.tryParse(s)),
            onLngChanged: (s) => notifier.setLongitude(double.tryParse(s)),
            isLocating: _isLocating,
            onUsePosition: _handleUsePosition,
          ),
          const SizedBox(height: AppSpacing.s4),
          _MethodSection(method: state.method, onChanged: notifier.setMethod),
          const SizedBox(height: AppSpacing.s4),
          _MadhabSection(madhab: state.madhab, onChanged: notifier.setMadhab),
          if (state.needsHighLatitudeRule) ...[
            const SizedBox(height: AppSpacing.s4),
            _HighLatitudeSection(
              value: state.highLatitudeRule,
              onChanged: notifier.setHighLatitudeRule,
            ),
          ],
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.s4),
            _ErrorBanner(error: state.error!),
          ],
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            key: const Key('sa02-save-button'),
            label: state.isSaving ? 'Enregistrement…' : 'Enregistrer',
            onPressed: state.isSaving
                ? null
                : () async {
                    final ok = await notifier.save();
                    if (ok && mounted) widget.onSaved();
                  },
          ),
          const SizedBox(height: AppSpacing.s6),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final ValueChanged<String> onLatChanged;
  final ValueChanged<String> onLngChanged;
  final bool isLocating;
  final VoidCallback onUsePosition;
  const _LocationSection({
    required this.latCtrl,
    required this.lngCtrl,
    required this.onLatChanged,
    required this.onLngChanged,
    required this.isLocating,
    required this.onUsePosition,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Position', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.s3),
          AppButton(
            key: const Key('sa02-use-position-button'),
            label: isLocating ? 'Localisation en cours…' : 'Ma position GPS',
            leadingIcon: LucideIcons.locateFixed,
            // #126 : spinner visible pendant la géolocalisation.
            isLoading: isLocating,
            variant: AppButtonVariant.ghost,
            onPressed: onUsePosition,
          ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(
            key: const Key('sa02-latitude-input'),
            label: 'Latitude',
            placeholder: 'ex. 48.8566',
            controller: latCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: onLatChanged,
          ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(
            key: const Key('sa02-longitude-input'),
            label: 'Longitude',
            placeholder: 'ex. 2.3522',
            controller: lngCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            onChanged: onLngChanged,
          ),
        ],
      ),
    );
  }
}

class _MethodSection extends StatelessWidget {
  final CalculationMethod method;
  final ValueChanged<CalculationMethod> onChanged;
  const _MethodSection({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Méthode de calcul', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.s3),
          for (final m in CalculationMethod.values)
            InkWell(
              onTap: () => onChanged(m),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_methodLabel(m), style: AppTypography.body),
                    ),
                    if (method == m)
                      const Icon(
                        LucideIcons.check,
                        size: 16,
                        color: AppColors.accent,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _methodLabel(CalculationMethod m) {
    switch (m) {
      case CalculationMethod.muslimWorldLeague:
        return 'Muslim World League';
      case CalculationMethod.isna:
        return 'ISNA (Amérique du Nord)';
      case CalculationMethod.egyptian:
        return 'Egyptian General Authority';
      case CalculationMethod.karachi:
        return 'Karachi';
      case CalculationMethod.ummAlQura:
        return 'Umm al-Qura (Arabie saoudite)';
      case CalculationMethod.diyanet:
        return 'Diyanet (Turquie)';
      case CalculationMethod.tehran:
        return 'Tehran';
      case CalculationMethod.moonsighting:
        return 'Moonsighting Committee';
      case CalculationMethod.singapore:
        return 'Singapore (MUIS)';
      case CalculationMethod.dubai:
        return 'Dubaï (EAU)';
      case CalculationMethod.qatar:
        return 'Qatar';
      case CalculationMethod.kuwait:
        return 'Koweït';
      case CalculationMethod.uoif:
        return 'UOIF (France)';
      case CalculationMethod.morocco:
        return 'Maroc';
      case CalculationMethod.algeria:
        return 'Algérie';
      case CalculationMethod.tunisia:
        return 'Tunisie';
    }
  }
}

class _MadhabSection extends StatelessWidget {
  final Madhab madhab;
  final ValueChanged<Madhab> onChanged;
  const _MadhabSection({required this.madhab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('École juridique', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  madhab == Madhab.hanafi ? 'Hanafi (Asr tardif)' : 'Shafi',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppToggle(
            value: madhab == Madhab.hanafi,
            semanticLabel: 'École Hanafi',
            onChanged: (v) => onChanged(v ? Madhab.hanafi : Madhab.shafi),
          ),
        ],
      ),
    );
  }
}

class _HighLatitudeSection extends StatelessWidget {
  final HighLatitudeRule value;
  final ValueChanged<HighLatitudeRule> onChanged;
  const _HighLatitudeSection({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hautes latitudes', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.s3),
          for (final rule in HighLatitudeRule.values)
            InkWell(
              onTap: () => onChanged(rule),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                child: Row(
                  children: [
                    Icon(
                      value == rule
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      size: 20,
                      color: value == rule
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Text(_label(rule), style: AppTypography.body),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _label(HighLatitudeRule rule) {
    switch (rule) {
      case HighLatitudeRule.middleOfTheNight:
        return 'Milieu de la nuit';
      case HighLatitudeRule.seventhOfTheNight:
        return 'Dernier septième de la nuit';
      case HighLatitudeRule.twilightAngle:
        return 'Angle crépusculaire';
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final PrayerSettingsFormError error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger),
      ),
      child: Text(
        _message(error),
        style: AppTypography.body.copyWith(color: AppColors.danger),
      ),
    );
  }

  static String _message(PrayerSettingsFormError e) {
    switch (e) {
      case PrayerSettingsFormError.missingCoordinates:
        return 'Renseigne ta latitude et ta longitude pour continuer.';
      case PrayerSettingsFormError.invalidLatitude:
        return 'Latitude invalide (attendu entre -90 et 90).';
      case PrayerSettingsFormError.invalidLongitude:
        return 'Longitude invalide (attendu entre -180 et 180).';
      case PrayerSettingsFormError.saveFailed:
        return 'Impossible d\'enregistrer. Réessaie dans un instant.';
    }
  }
}
