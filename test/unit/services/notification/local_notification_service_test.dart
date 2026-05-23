// Tests RED → GREEN — LocalNotificationService (MOB-002, issue #170).
// Cf. ADR-018 §4.1 (contrat figé), §3.2 (actions), §3.3 (no-snooze prière).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/notification_action.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/entities/scheduled_notification.dart';
import 'package:murabbi_mobile/services/notification/local_notification_service.dart';
import 'package:murabbi_mobile/services/notification/notification_platform.dart';

class _MockPlatform extends Mock implements NotificationPlatform {}

class _FakeScheduleRequest extends Fake implements PlatformScheduleRequest {}

void main() {
  late _MockPlatform platform;
  late LocalNotificationService service;

  setUpAll(() {
    registerFallbackValue(_FakeScheduleRequest());
  });

  setUp(() {
    platform = _MockPlatform();
    service = LocalNotificationService(platform: platform);

    when(
      () =>
          platform.initialize(onActionReceived: any(named: 'onActionReceived')),
    ).thenAnswer((_) async {});
    when(() => platform.requestPermission()).thenAnswer((_) async => true);
    when(
      () => platform.permissionStatus(),
    ).thenAnswer((_) async => NotificationPermissionStatus.granted);
    when(() => platform.schedule(any())).thenAnswer((_) async {});
    when(() => platform.cancel(any())).thenAnswer((_) async {});
    when(() => platform.cancelAll()).thenAnswer((_) async {});
  });

  ScheduledNotification habitSpec({
    String occurrenceId = 'occ-001',
    DateTime? scheduledAt,
    List<NotificationActionId>? actions,
  }) {
    return ScheduledNotification(
      occurrenceId: occurrenceId,
      source: OccurrenceSource.habit,
      scheduledAt: scheduledAt ?? DateTime.utc(2026, 5, 23, 8),
      title: 'Lecture Coran',
      body: '15 min — page 42',
      actions:
          actions ??
          const [
            NotificationActionId.done,
            NotificationActionId.later,
            NotificationActionId.dismiss,
          ],
      payload: const {'sourceId': 'habit-001', 'deeplink': '/habits/habit-001'},
    );
  }

  ScheduledNotification prayerSpec({String occurrenceId = 'occ-prayer-001'}) {
    return ScheduledNotification(
      occurrenceId: occurrenceId,
      source: OccurrenceSource.prayer,
      scheduledAt: DateTime.utc(2026, 5, 23, 13, 30),
      title: 'Dhuhr',
      body: 'La fenêtre de prière s\'ouvre',
      actions: const [NotificationActionId.done, NotificationActionId.dismiss],
      payload: const {'sourceId': 'dhuhr'},
    );
  }

  group('LocalNotificationService — initialize / permissions', () {
    test('initialize() délègue au platform avec un callback', () async {
      await service.initialize();

      verify(
        () => platform.initialize(
          onActionReceived: any(named: 'onActionReceived'),
        ),
      ).called(1);
    });

    test('requestPermission() retourne true si accordée', () async {
      when(() => platform.requestPermission()).thenAnswer((_) async => true);

      final granted = await service.requestPermission();

      expect(granted, isTrue);
    });

    test('requestPermission() retourne false si refusée', () async {
      when(() => platform.requestPermission()).thenAnswer((_) async => false);

      final granted = await service.requestPermission();

      expect(granted, isFalse);
    });

    test('permissionStatus() délègue au platform', () async {
      when(
        () => platform.permissionStatus(),
      ).thenAnswer((_) async => NotificationPermissionStatus.denied);

      final status = await service.permissionStatus();

      expect(status, NotificationPermissionStatus.denied);
    });
  });

  group('LocalNotificationService — schedule', () {
    test(
      'schedule() délègue au platform avec id, payload et actions de la spec',
      () async {
        final spec = habitSpec();

        await service.schedule(spec);

        final req =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;
        expect(req.notificationId, isA<int>());
        expect(req.title, 'Lecture Coran');
        expect(req.body, '15 min — page 42');
        expect(req.scheduledAt, spec.scheduledAt);
        expect(req.actions, spec.actions);
        // Payload est sérialisé en JSON et contient occurrenceId + custom keys.
        expect(req.payload, contains('occ-001'));
        expect(req.payload, contains('habit-001'));
      },
    );

    test(
      'schedule() habit avec 3 actions → platform reçoit [done, later, dismiss]',
      () async {
        await service.schedule(habitSpec());

        final req =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;
        expect(req.actions, [
          NotificationActionId.done,
          NotificationActionId.later,
          NotificationActionId.dismiss,
        ]);
      },
    );

    test(
      'schedule() prayer avec 2 actions → platform reçoit [done, dismiss] (BUG-004)',
      () async {
        await service.schedule(prayerSpec());

        final req =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;
        expect(req.actions, [
          NotificationActionId.done,
          NotificationActionId.dismiss,
        ]);
        expect(req.actions, isNot(contains(NotificationActionId.later)));
      },
    );

    test(
      'schedule() est idempotent : 2 appels avec même occurrenceId → cancel puis schedule',
      () async {
        final spec = habitSpec();

        await service.schedule(spec);
        await service.schedule(spec);

        // Au 2e schedule, le service doit avoir annulé la précédente avant.
        verify(() => platform.cancel(any())).called(greaterThanOrEqualTo(1));
        verify(() => platform.schedule(any())).called(2);
      },
    );

    test(
      'notificationId est un hash stable de occurrenceId (mêmes id → même hash)',
      () async {
        await service.schedule(habitSpec(occurrenceId: 'occ-stable'));
        final req1 =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;

        clearInteractions(platform);
        when(() => platform.schedule(any())).thenAnswer((_) async {});
        when(() => platform.cancel(any())).thenAnswer((_) async {});

        await service.schedule(habitSpec(occurrenceId: 'occ-stable'));
        final req2 =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;

        expect(req1.notificationId, req2.notificationId);
      },
    );

    test(
      'notificationIds de deux occurrences différentes ne collisionnent pas',
      () async {
        await service.schedule(habitSpec(occurrenceId: 'occ-A'));
        final reqA =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;

        clearInteractions(platform);
        when(() => platform.schedule(any())).thenAnswer((_) async {});
        when(() => platform.cancel(any())).thenAnswer((_) async {});

        await service.schedule(habitSpec(occurrenceId: 'occ-B'));
        final reqB =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;

        expect(reqA.notificationId, isNot(reqB.notificationId));
      },
    );

    test(
      'notificationId reste dans la plage int32 (compat iOS/Android)',
      () async {
        await service.schedule(
          habitSpec(occurrenceId: 'a-very-long-uuid-string-${'x' * 100}'),
        );

        final req =
            verify(() => platform.schedule(captureAny())).captured.first
                as PlatformScheduleRequest;
        expect(req.notificationId, lessThanOrEqualTo(0x7FFFFFFF));
        expect(req.notificationId, greaterThanOrEqualTo(0));
      },
    );
  });

  group('LocalNotificationService — cancel', () {
    test('cancel() délègue au platform avec le notificationId hashé', () async {
      // On planifie d'abord pour connaître le hash utilisé.
      await service.schedule(habitSpec(occurrenceId: 'occ-cancel'));
      final scheduled =
          verify(() => platform.schedule(captureAny())).captured.first
              as PlatformScheduleRequest;

      clearInteractions(platform);
      when(() => platform.cancel(any())).thenAnswer((_) async {});

      await service.cancel('occ-cancel');

      verify(() => platform.cancel(scheduled.notificationId)).called(1);
    });

    test('cancel() id inconnu → no-op (pas d\'erreur)', () async {
      await service.cancel('jamais-planifié');

      // Le service doit quand même appeler platform.cancel défensivement
      // (l'OS gère gracieusement un id inexistant).
      verify(() => platform.cancel(any())).called(1);
    });

    test('cancelAll() délègue au platform', () async {
      await service.cancelAll();

      verify(() => platform.cancelAll()).called(1);
    });
  });

  group('LocalNotificationService — actionStream', () {
    test('est broadcast (supporte plusieurs subscribers)', () async {
      await service.initialize();

      final stream = service.actionStream;
      final sub1 = stream.listen((_) {});
      final sub2 = stream.listen((_) {});

      // Si non-broadcast, le 2e listen() throw.
      await sub1.cancel();
      await sub2.cancel();
    });

    test('reçoit un évènement quand le platform invoque le callback', () async {
      late void Function(NotificationAction) capturedCallback;
      when(
        () => platform.initialize(
          onActionReceived: any(named: 'onActionReceived'),
        ),
      ).thenAnswer((invocation) async {
        capturedCallback =
            invocation.namedArguments[const Symbol('onActionReceived')]
                as void Function(NotificationAction);
      });

      await service.initialize();

      final events = <NotificationAction>[];
      final sub = service.actionStream.listen(events.add);

      final received = NotificationAction(
        occurrenceId: 'occ-001',
        actionId: NotificationActionId.done,
        receivedAt: DateTime.utc(2026, 5, 23, 8, 5),
        payload: const {'sourceId': 'habit-001'},
      );
      capturedCallback(received);

      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.first.occurrenceId, 'occ-001');
      expect(events.first.actionId, NotificationActionId.done);

      await sub.cancel();
    });

    test('émet les 3 actions done/later/dismiss correctement', () async {
      late void Function(NotificationAction) capturedCallback;
      when(
        () => platform.initialize(
          onActionReceived: any(named: 'onActionReceived'),
        ),
      ).thenAnswer((invocation) async {
        capturedCallback =
            invocation.namedArguments[const Symbol('onActionReceived')]
                as void Function(NotificationAction);
      });

      await service.initialize();

      final events = <NotificationActionId>[];
      final sub = service.actionStream.listen((a) => events.add(a.actionId));

      final now = DateTime.utc(2026, 5, 23, 8, 5);
      capturedCallback(
        NotificationAction(
          occurrenceId: 'a',
          actionId: NotificationActionId.done,
          receivedAt: now,
        ),
      );
      capturedCallback(
        NotificationAction(
          occurrenceId: 'b',
          actionId: NotificationActionId.later,
          receivedAt: now,
        ),
      );
      capturedCallback(
        NotificationAction(
          occurrenceId: 'c',
          actionId: NotificationActionId.dismiss,
          receivedAt: now,
        ),
      );

      await Future<void>.delayed(Duration.zero);
      expect(events, [
        NotificationActionId.done,
        NotificationActionId.later,
        NotificationActionId.dismiss,
      ]);

      await sub.cancel();
    });
  });
}
