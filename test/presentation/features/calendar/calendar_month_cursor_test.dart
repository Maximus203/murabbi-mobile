import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/presentation/features/calendar/providers/calendar_month_notifier.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  CalendarMonthCursor cursor() =>
      container.read(calendarMonthCursorProvider.notifier);

  test('starts on the current month', () {
    final now = DateTime.now();
    final state = container.read(calendarMonthCursorProvider);
    expect(state.year, now.year);
    expect(state.month, now.month);
  });

  test('previousMonth wraps the year backwards in January', () {
    // Force janvier en navigant jusqu'à un mois connu impossible — on teste
    // le wrap via la sémantique DateTime : mois 0 -> décembre précédent.
    cursor().goToMonth(2026, 1);
    cursor().previousMonth();
    expect(container.read(calendarMonthCursorProvider), DateTime(2025, 12));
  });

  test('nextMonth wraps the year forwards in December', () {
    cursor().goToMonth(2026, 12);
    cursor().nextMonth();
    expect(container.read(calendarMonthCursorProvider), DateTime(2027, 1));
  });

  test('previousMonth then nextMonth returns to the same month', () {
    cursor().goToMonth(2026, 5);
    cursor()
      ..previousMonth()
      ..nextMonth();
    expect(container.read(calendarMonthCursorProvider), DateTime(2026, 5));
  });
}
