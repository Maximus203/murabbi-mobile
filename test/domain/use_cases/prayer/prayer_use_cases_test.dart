import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/prayer_day.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/domain/repositories/prayer_repository.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_prayer_history_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/get_today_prayers_use_case.dart';
import 'package:murabbi_mobile/domain/use_cases/prayer/mark_prayer_use_case.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

class MockPrayerRepository extends Mock implements PrayerRepository {}

void main() {
  late MockPrayerRepository mockRepo;
  final userId = UserId('user-uuid-001');
  final today = DateTime(2026, 4, 27);

  final testDay = PrayerDay(
    userId: userId,
    date: today,
    fajr: PrayerStatus.pending,
    dhuhr: PrayerStatus.pending,
    asr: PrayerStatus.pending,
    maghrib: PrayerStatus.pending,
    isha: PrayerStatus.pending,
  );

  setUp(() {
    mockRepo = MockPrayerRepository();
  });

  group('GetTodayPrayersUseCase', () {
    late GetTodayPrayersUseCase useCase;

    setUp(() => useCase = GetTodayPrayersUseCase(mockRepo));

    test('calls repository.getTodayPrayers and returns PrayerDay', () async {
      when(
        () => mockRepo.getTodayPrayers(userId),
      ).thenAnswer((_) async => testDay);

      final result = await useCase(userId);

      expect(result, testDay);
      verify(() => mockRepo.getTodayPrayers(userId)).called(1);
    });
  });

  group('MarkPrayerUseCase', () {
    late MarkPrayerUseCase useCase;

    setUp(() => useCase = MarkPrayerUseCase(mockRepo));

    test('calls repository.markPrayer with correct params', () async {
      when(
        () => mockRepo.markPrayer(
          userId: userId,
          date: today,
          prayerName: 'fajr',
          status: PrayerStatus.onTime,
        ),
      ).thenAnswer((_) async {});

      await useCase(
        userId: userId,
        date: today,
        prayerName: 'fajr',
        status: PrayerStatus.onTime,
      );

      verify(
        () => mockRepo.markPrayer(
          userId: userId,
          date: today,
          prayerName: 'fajr',
          status: PrayerStatus.onTime,
        ),
      ).called(1);
    });
  });

  group('GetPrayerHistoryUseCase', () {
    late GetPrayerHistoryUseCase useCase;
    final from = DateTime(2026, 4, 1);
    final to = DateTime(2026, 4, 27);

    setUp(() => useCase = GetPrayerHistoryUseCase(mockRepo));

    test('calls repository.getPrayerHistory and returns list', () async {
      when(
        () => mockRepo.getPrayerHistory(userId: userId, from: from, to: to),
      ).thenAnswer((_) async => [testDay]);

      final result = await useCase(userId: userId, from: from, to: to);

      expect(result, [testDay]);
      verify(
        () => mockRepo.getPrayerHistory(userId: userId, from: from, to: to),
      ).called(1);
    });
  });
}
