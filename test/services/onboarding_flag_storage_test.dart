import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/services/onboarding_flag_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('isCompleted() returns false when flag never written', () async {
    final storage = OnboardingFlagStorage();
    expect(await storage.isCompleted(), isFalse);
  });

  test('markCompleted() persists then isCompleted() returns true', () async {
    final storage = OnboardingFlagStorage();
    await storage.markCompleted();
    expect(await storage.isCompleted(), isTrue);
  });

  test('markCompleted() is idempotent', () async {
    final storage = OnboardingFlagStorage();
    await storage.markCompleted();
    await storage.markCompleted();
    expect(await storage.isCompleted(), isTrue);
  });

  test('reset() clears the flag', () async {
    final storage = OnboardingFlagStorage();
    await storage.markCompleted();
    await storage.reset();
    expect(await storage.isCompleted(), isFalse);
  });

  test(
    'survives a fresh storage instance (persisted to SharedPreferences)',
    () async {
      await OnboardingFlagStorage().markCompleted();
      final freshStorage = OnboardingFlagStorage();
      expect(await freshStorage.isCompleted(), isTrue);
    },
  );

  test('persists under the new "onboarding_seen_v1" key', () async {
    final storage = OnboardingFlagStorage();
    await storage.markCompleted();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_seen_v1'), isTrue);
  });

  test(
    'migrates legacy "onboarding_completed_v1=true" to the new key (Q3-A)',
    () async {
      // Ancien flag pose par une version anterieure de l'app : on doit
      // le considerer comme onboarding_seen=true sans recasser le user.
      SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
      final storage = OnboardingFlagStorage();
      expect(await storage.isCompleted(), isTrue);
    },
  );

  test(
    'legacy flag at false does NOT block the new onboarding (Q3-A)',
    () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed_v1': false,
      });
      final storage = OnboardingFlagStorage();
      expect(await storage.isCompleted(), isFalse);
    },
  );
}
