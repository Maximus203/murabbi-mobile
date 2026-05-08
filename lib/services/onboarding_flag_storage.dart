import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stocke le flag "onboarding pédagogique pre-auth déjà vu" en
/// SharedPreferences locales (Q3-A).
///
/// Sémantique : ce flag couvre le walkthrough marketing/pédagogique des 4
/// slides SETUP-01 (avant inscription). Une fois posé, l'utilisateur n'a
/// plus à le revoir au lancement — `authRedirect` enverra un visiteur
/// non-auth vers `/auth/login` plutôt que vers `/onboarding`.
///
/// Le bouton "Passer" et la touche dernière "Commencer" du walkthrough
/// posent ce flag.
///
/// **Migration douce** (cf. ADR-012) : si l'ancien flag
/// `onboarding_completed_v1=true` existe sur l'appareil utilisateur (issu
/// d'un build pre-Q3-A), on le considère comme `onboarding_seen_v1=true`.
///
/// **TODO Phase 3** : si un onboarding post-auth de configuration (settings
/// prière, etc.) est introduit, ajouter un second flag
/// `account_setup_completed` côté `users.account_setup_completed_at`
/// (cf. ADR-012 §Conséquences).
class OnboardingFlagStorage {
  static const _key = 'onboarding_seen_v1';
  static const _legacyKey = 'onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getBool(_key);
    if (current != null) return current;
    // Fallback : ancien flag d'avant Q3-A (cf. ADR-012). On migre seulement
    // s'il etait pose a true (un legacy=false n'est pas un signal — on
    // veut bien que le user voie le nouveau walkthrough).
    final legacy = prefs.getBool(_legacyKey);
    if (legacy == true) {
      await prefs.setBool(_key, true);
      return true;
    }
    return false;
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
