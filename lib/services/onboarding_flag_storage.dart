import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stocke le flag "onboarding terminé" en SharedPreferences locales.
///
/// MVP slice D — TODO Q-18 : migrer vers `users.onboarding_completed_at`
/// (boolean ou timestamp côté admin) quand la table `users` mobile sera
/// créée. Pour l'instant le flag est local au device : un user qui change
/// d'appareil refera le SETUP-01.
class OnboardingFlagStorage {
  static const _key = 'onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Provider injectable — surchargé en test pour passer un fake.
final onboardingFlagStorageProvider = Provider<OnboardingFlagStorage>(
  (ref) => OnboardingFlagStorage(),
);
