import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/core/utils/logger.dart';
import 'package:murabbi_mobile/domain/entities/prayer_settings.dart';
import 'package:murabbi_mobile/domain/value_objects/calculation_method.dart';
import 'package:murabbi_mobile/domain/value_objects/high_latitude_rule.dart';
import 'package:murabbi_mobile/domain/value_objects/madhab.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/prayer_settings_form_state.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/salat_use_case_providers.dart';

/// Notifier du formulaire SA-02 (slice 3.C.3).
///
/// État synchrone — les chargements (`loadInitial`) et sauvegardes (`save`)
/// sont des actions explicites. Le drapeau [PrayerSettingsFormState.isSaving]
/// reflète la persistance en cours.
class PrayerSettingsFormNotifier extends Notifier<PrayerSettingsFormState> {
  @override
  PrayerSettingsFormState build() => const PrayerSettingsFormState.initial();

  /// Hydrate le formulaire :
  /// - si des [PrayerSettings] sont déjà persistées → pré-remplissage complet ;
  /// - sinon, dérive la méthode par défaut à partir de [countryCode] (ADR-013
  ///   §2.1) et laisse les coordonnées vides.
  Future<void> loadInitial({String? countryCode}) async {
    final getSettings = await ref.read(getPrayerSettingsUseCaseProvider.future);
    final existing = await getSettings();

    if (existing != null) {
      state = state.copyWith(
        method: existing.method,
        madhab: existing.madhab,
        latitude: existing.latitude,
        longitude: existing.longitude,
        highLatitudeRule: existing.highLatitudeRule,
        clearError: true,
      );
      return;
    }

    final derive = ref.read(deriveDefaultMethodFromCountryUseCaseProvider);
    state = state.copyWith(method: derive(countryCode), clearError: true);
  }

  void setMethod(CalculationMethod method) {
    state = state.copyWith(method: method, clearError: true);
  }

  void setMadhab(Madhab madhab) {
    state = state.copyWith(madhab: madhab, clearError: true);
  }

  void setLatitude(double? latitude) {
    state = latitude == null
        ? state.copyWith(clearLatitude: true, clearError: true)
        : state.copyWith(latitude: latitude, clearError: true);
  }

  void setLongitude(double? longitude) {
    state = longitude == null
        ? state.copyWith(clearLongitude: true, clearError: true)
        : state.copyWith(longitude: longitude, clearError: true);
  }

  void setHighLatitudeRule(HighLatitudeRule rule) {
    state = state.copyWith(highLatitudeRule: rule, clearError: true);
  }

  /// Persiste les settings courants. Retourne `true` en cas de succès,
  /// `false` si la validation a échoué ou si le repository a levé une
  /// exception (cf. [PrayerSettingsFormState.error]).
  Future<bool> save() async {
    final lat = state.latitude;
    final lng = state.longitude;
    if (lat == null || lng == null) {
      state = state.copyWith(error: PrayerSettingsFormError.missingCoordinates);
      return false;
    }
    if (lat < -90 || lat > 90) {
      state = state.copyWith(error: PrayerSettingsFormError.invalidLatitude);
      return false;
    }
    if (lng < -180 || lng > 180) {
      state = state.copyWith(error: PrayerSettingsFormError.invalidLongitude);
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final settings = PrayerSettings(
        method: state.method,
        madhab: state.madhab,
        latitude: lat,
        longitude: lng,
        highLatitudeRule: state.highLatitudeRule,
      );
      final saveUseCase = await ref.read(
        savePrayerSettingsUseCaseProvider.future,
      );
      await saveUseCase(settings);
      state = state.copyWith(isSaving: false, clearError: true);
      return true;
    } catch (e, stackTrace) {
      // Capture l'exception pour debug. Audit TL §B.2 (PR #38) : ne pas
      // swallow muettement. appLog (package:logger) est le pattern logging
      // du projet (cf. ADR-016, règle §6 CLAUDE.md).
      appLog.e(
        'PrayerSettingsFormNotifier.save failed',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSaving: false,
        error: PrayerSettingsFormError.saveFailed,
      );
      return false;
    }
  }
}

final prayerSettingsFormNotifierProvider =
    NotifierProvider<PrayerSettingsFormNotifier, PrayerSettingsFormState>(
      PrayerSettingsFormNotifier.new,
    );
