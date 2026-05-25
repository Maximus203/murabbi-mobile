import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/providers/onboarding_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('build() returns false when no flag stored', () async {
    final c = makeContainer();
    expect(await c.read(onboardingNotifierProvider.future), isFalse);
  });

  test('markCompleted() flips state to true', () async {
    final c = makeContainer();
    await c.read(onboardingNotifierProvider.future);
    await c.read(onboardingNotifierProvider.notifier).markCompleted();
    expect(c.read(onboardingNotifierProvider).valueOrNull, isTrue);
  });

  test('reset() flips state back to false', () async {
    final c = makeContainer();
    await c.read(onboardingNotifierProvider.future);
    await c.read(onboardingNotifierProvider.notifier).markCompleted();
    await c.read(onboardingNotifierProvider.notifier).reset();
    expect(c.read(onboardingNotifierProvider).valueOrNull, isFalse);
  });
}
