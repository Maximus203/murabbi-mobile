import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/services/onboarding_flag_storage.dart';

/// État sync de l'onboarding (`true` = terminé). Wrappe
/// [OnboardingFlagStorage] dans un `AsyncNotifier<bool>` pour permettre au
/// router de redirecter en synchronisation avec l'auth.
class OnboardingNotifier extends AsyncNotifier<bool> {
  late OnboardingFlagStorage _storage;

  @override
  Future<bool> build() async {
    _storage = ref.read(onboardingFlagStorageProvider);
    return _storage.isCompleted();
  }

  Future<void> markCompleted() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _storage.markCompleted();
      return true;
    });
  }

  Future<void> reset() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _storage.reset();
      return false;
    });
  }
}

final onboardingNotifierProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
