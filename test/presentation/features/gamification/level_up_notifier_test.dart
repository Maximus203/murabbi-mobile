import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/presentation/features/gamification/providers/level_up_notifier.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  LevelUpNotifier notifier() =>
      container.read(levelUpNotifierProvider.notifier);

  test('starts with no pending level-up', () {
    expect(container.read(levelUpNotifierProvider), isNull);
  });

  test('first observed total is a reference only — no trigger', () {
    notifier().observeTotal(50000);
    expect(container.read(levelUpNotifierProvider), isNull);
  });

  test('triggers the overlay when a threshold is crossed', () {
    notifier()
      ..observeTotal(9990)
      ..observeTotal(10010);
    expect(container.read(levelUpNotifierProvider), Level.murid);
  });

  test('does not trigger when staying within the same level', () {
    notifier()
      ..observeTotal(100)
      ..observeTotal(500);
    expect(container.read(levelUpNotifierProvider), isNull);
  });

  test('acknowledge clears the pending level-up', () {
    notifier()
      ..observeTotal(9990)
      ..observeTotal(10010);
    expect(container.read(levelUpNotifierProvider), Level.murid);

    notifier().acknowledge();
    expect(container.read(levelUpNotifierProvider), isNull);
  });
}
