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
}
