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
import 'package:murabbi_mobile/presentation/widgets/app_snackbar.dart';
import 'package:murabbi_mobile/presentation/widgets/app_toggle.dart';
import 'package:murabbi_mobile/services/geocoding/geocoding_service.dart';
import 'package:murabbi_mobile/services/location/location_service.dart';

/// SA-02 — Écran de réglages des prières (slice 3.C.3).
///
/// Redesigné pour correspondre aux maquettes : pas d'AppBar, titre "Vos prières."
/// intégré dans le corps. La localisation est un champ unique (ville résolue par
/// géocodage inverse Nominatim) activé par le bouton GPS. Pas de saisie manuelle
/// de lat/lng exposée à l'utilisateur — les coordonnées brutes sont stockées dans
/// le state pour le calcul, mais seul le libellé de ville est affiché.
///
/// DST toggle (heure d'été) visible sous la localisation.
/// CTA principal : "Continuer" + lien "Configurer plus tard".
class Sa02PrayerSettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  final VoidCallback onBack;

  /// Callback "Configurer plus tard" — permet à l'utilisateur de passer sans
  /// sauvegarder. Le caller décide de la navigation.
  final VoidCallback? onSkip;

  const Sa02PrayerSettingsScreen({
    super.key,
    required this.onSaved,
    required this.onBack,
    this.onSkip,
  });

  @override
  ConsumerState<Sa02PrayerSettingsScreen> createState() =>
      _Sa02PrayerSettingsScreenState();
}

class _Sa02PrayerSettingsScreenState
    extends ConsumerState<Sa02PrayerSettingsScreen> {
  bool _isLocating = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(prayerSettingsFormNotifierProvider.notifier).loadInitial();
    });
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
        notifier
          ..setLatitude(latitude)
          ..setLongitude(longitude);

        // Géocodage inverse pour afficher la ville
        setState(() => _isGeocoding = true);
        final geo = ref.read(geocodingServiceProvider);
        final geoResult = await geo.reverseGeocode(
          latitude: latitude,
          longitude: longitude,
        );
        if (!mounted) return;
        setState(() => _isGeocoding = false);

        switch (geoResult) {
          case GeocodingSuccess(:final label):
            notifier.setLocationLabel(label);
          case GeocodingFailure():
            // Non bloquant : les coordonnées sont stockées, seul le label échoue.
            appLog.w('SA-02 geocoding failed — coordinates saved anyway');
            notifier.setLocationLabel(
              '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}',
            );
        }

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
        appLog.e('GPS getCurrentPosition unknown error', error: message);
        _showSnack('Erreur lors de la localisation. Réessaie dans un instant.');
    }
  }

  void _showSnack(
    String message, {
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
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
      // Pas d'AppBar — le titre est dans le body (conforme maquette SA-02).
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s6,
            AppSpacing.s5,
            AppSpacing.s8,
          ),
          children: [
            // ── Bouton retour ──────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                label: 'Retour',
                child: GestureDetector(
                  onTap: widget.onBack,
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    size: AppIconSize.nav,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s5),

            // ── Grand titre "Vos prières." ─────────────────────────────────
            const Text('Vos prières.', style: AppTypography.h1),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Configurez votre position et votre méthode de calcul pour des '
              'horaires précis.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),

            // ── Localisation ───────────────────────────────────────────────
            _LocationCard(
              locationLabel: state.locationLabel,
              isLocating: _isLocating || _isGeocoding,
              onUsePosition: _handleUsePosition,
            ),
            const SizedBox(height: AppSpacing.s3),

            // ── DST toggle ────────────────────────────────────────────────
            _DstCard(
              value: state.useDst,
              onChanged: (v) => notifier.setUseDst(value: v),
            ),
            const SizedBox(height: AppSpacing.s4),

            // ── Méthode de calcul ─────────────────────────────────────────
            _MethodCard(method: state.method, onChanged: notifier.setMethod),
            const SizedBox(height: AppSpacing.s3),

            // ── École juridique ───────────────────────────────────────────
            _MadhabCard(madhab: state.madhab, onChanged: notifier.setMadhab),

            // ── Hautes latitudes (|lat| > 48°) ────────────────────────────
            if (state.needsHighLatitudeRule) ...[
              const SizedBox(height: AppSpacing.s3),
              _HighLatitudeCard(
                value: state.highLatitudeRule,
                onChanged: notifier.setHighLatitudeRule,
              ),
            ],

            // ── Bannière d'erreur ─────────────────────────────────────────
            if (state.error != null) ...[
              const SizedBox(height: AppSpacing.s4),
              _ErrorBanner(error: state.error!),
            ],

            const SizedBox(height: AppSpacing.s6),

            // ── CTA "Continuer" ───────────────────────────────────────────
            AppButton(
              key: const Key('sa02-save-button'),
              label: state.isSaving ? 'Enregistrement…' : 'Continuer',
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final ok = await notifier.save();
                      if (ok && mounted) widget.onSaved();
                    },
            ),
            const SizedBox(height: AppSpacing.s3),

            // ── Lien "Configurer plus tard" ───────────────────────────────
            if (widget.onSkip != null)
              Center(
                child: AppButton(
                  label: 'Configurer plus tard',
                  variant: AppButtonVariant.link,
                  onPressed: widget.onSkip,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Champ de localisation — affiche le libellé de ville ou un placeholder.
/// Bouton GPS intégré dans le champ.
class _LocationCard extends StatelessWidget {
  final String? locationLabel;
  final bool isLocating;
  final VoidCallback onUsePosition;

  const _LocationCard({
    required this.locationLabel,
    required this.isLocating,
    required this.onUsePosition,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Localisation',
            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s3),
          // Champ de localisation avec bouton GPS inline
          GestureDetector(
            onTap: isLocating ? null : onUsePosition,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s3,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isLocating
                          ? 'Localisation en cours…'
                          : (locationLabel ??
                                'Appuyer pour détecter ma position'),
                      style: AppTypography.body.copyWith(
                        color: locationLabel != null && !isLocating
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  if (isLocating)
                    const SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                        strokeWidth: AppBorderWidth.indicatorStroke,
                        color: AppColors.accent,
                      ),
                    )
                  else
                    const Icon(
                      LucideIcons.locateFixed,
                      size: AppIconSize.sm,
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
}

/// Toggle heure d'été (DST).
class _DstCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DstCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heure d\'été automatique', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  'Ajuste automatiquement l\'heure selon la saison.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          AppToggle(
            value: value,
            semanticLabel: 'Heure d\'été automatique',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final CalculationMethod method;
  final ValueChanged<CalculationMethod> onChanged;
  const _MethodCard({required this.method, required this.onChanged});

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
                        size: AppIconSize.sm,
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

class _MadhabCard extends StatelessWidget {
  final Madhab madhab;
  final ValueChanged<Madhab> onChanged;
  const _MadhabCard({required this.madhab, required this.onChanged});

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

class _HighLatitudeCard extends StatelessWidget {
  final HighLatitudeRule value;
  final ValueChanged<HighLatitudeRule> onChanged;
  const _HighLatitudeCard({required this.value, required this.onChanged});

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
                      size: AppIconSize.rg,
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
        borderRadius: BorderRadius.circular(AppRadius.button),
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
        return 'Utilise le bouton GPS pour détecter ta position.';
      case PrayerSettingsFormError.invalidLatitude:
        return 'Latitude invalide (attendu entre -90 et 90).';
      case PrayerSettingsFormError.invalidLongitude:
        return 'Longitude invalide (attendu entre -180 et 180).';
      case PrayerSettingsFormError.saveFailed:
        return 'Impossible d\'enregistrer. Réessaie dans un instant.';
    }
  }
}
