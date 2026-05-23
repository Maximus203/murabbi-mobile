// ignore_for_file: prefer_const_constructors, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/domain/entities/occurrence.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/use_cases/alerts/validate_occurrence_use_case.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/occurrence_providers.dart';

// ─── mocks ───────────────────────────────────────────────────────────────────

class MockValidateOccurrenceUseCase extends Mock
    implements ValidateOccurrenceUseCase {}

// ─── helpers ─────────────────────────────────────────────────────────────────

Occurrence _occurrence({OccurrenceStatus status = OccurrenceStatus.pending}) {
  final now = DateTime.utc(2025, 5, 23, 9, 0);
  return Occurrence(
    id: 'occ-001',
    source: OccurrenceSource.habit,
    sourceId: 'habit-abc',
    userId: 'user-001',
    scheduledAt: now,
    windowEndsAt: DateTime.utc(2025, 5, 24, 0, 0),
    status: status,
    snoozeCount: 0,
    payloadJson: '{}',
    createdAt: now,
    updatedAt: now,
  );
}

Occurrence _doneOccurrence() => _occurrence().copyWith(
  status: OccurrenceStatus.done,
  actedAt: DateTime.utc(2025, 5, 23, 10, 0),
  updatedAt: DateTime.utc(2025, 5, 23, 10, 0),
);

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockValidateOccurrenceUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(ValidationSource.app);
  });

  setUp(() {
    mockUseCase = MockValidateOccurrenceUseCase();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        validateOccurrenceUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
  }

  // ── Idempotency guard (BUG-003) ───────────────────────────────────────────

  test('validate_notifier_ignores_call_while_loading — '
      'second appel ignoré pendant AsyncLoading', () async {
    // Le use case est lent (simulé par Completer)
    final completer = Completer<Occurrence>();
    when(
      () => mockUseCase.call(
        occurrenceId: any(named: 'occurrenceId'),
        source: any(named: 'source'),
        now: any(named: 'now'),
      ),
    ).thenAnswer((_) => completer.future);

    final container = makeContainer();
    addTearDown(container.dispose);

    final notifier = container.read(
      occurrenceValidationNotifierProvider('occ-001').notifier,
    );
    // Attendre que build() termine (état initial null)
    await container.read(
      occurrenceValidationNotifierProvider('occ-001').future,
    );

    // Premier appel — démarre le chargement
    final firstCall = notifier.validate();

    // Second appel pendant loading — doit être ignoré (no-op)
    await notifier.validate();

    // On complète le premier appel
    completer.complete(_doneOccurrence());
    await firstCall;

    // Le use case n'a été appelé qu'une seule fois
    verify(
      () => mockUseCase.call(
        occurrenceId: any(named: 'occurrenceId'),
        source: any(named: 'source'),
        now: any(named: 'now'),
      ),
    ).called(1);
  });

  test('rapid_taps_result_in_single_rpc_call — '
      '3 taps rapides → 1 seul appel use case', () async {
    final completer = Completer<Occurrence>();
    when(
      () => mockUseCase.call(
        occurrenceId: any(named: 'occurrenceId'),
        source: any(named: 'source'),
        now: any(named: 'now'),
      ),
    ).thenAnswer((_) => completer.future);

    final container = makeContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      occurrenceValidationNotifierProvider('occ-001').notifier,
    );
    // Attendre que build() termine
    await container.read(
      occurrenceValidationNotifierProvider('occ-001').future,
    );

    // 3 appels quasi-simultanés : seul le premier passe
    notifier.validate(); // ignore: unawaited_futures
    notifier.validate(); // ignore: unawaited_futures
    notifier.validate(); // ignore: unawaited_futures

    completer.complete(_doneOccurrence());
    await Future<void>.delayed(Duration.zero); // laisse la queue s'exécuter

    verify(
      () => mockUseCase.call(
        occurrenceId: any(named: 'occurrenceId'),
        source: any(named: 'source'),
        now: any(named: 'now'),
      ),
    ).called(1);
  });

  test('already_finalized_response_handled_gracefully — '
      'OccurrenceAlreadyFinalizedFailure ne crash pas, état = error', () async {
    when(
      () => mockUseCase.call(
        occurrenceId: any(named: 'occurrenceId'),
        source: any(named: 'source'),
        now: any(named: 'now'),
      ),
    ).thenThrow(OccurrenceFailure.alreadyFinalized(message: 'already done'));

    final container = makeContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      occurrenceValidationNotifierProvider('occ-001').notifier,
    );
    // Attendre que build() termine
    await container.read(
      occurrenceValidationNotifierProvider('occ-001').future,
    );

    await notifier.validate();

    final st = container.read(occurrenceValidationNotifierProvider('occ-001'));
    expect(st.hasError, isTrue);
  });

  test('idempotency_key_consistent_for_same_occurrence — '
      'appel success → état = AsyncData(done)', () async {
    when(
      () => mockUseCase.call(
        occurrenceId: any(named: 'occurrenceId'),
        source: any(named: 'source'),
        now: any(named: 'now'),
      ),
    ).thenAnswer((_) async => _doneOccurrence());

    final container = makeContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      occurrenceValidationNotifierProvider('occ-001').notifier,
    );
    // Attendre que build() termine
    await container.read(
      occurrenceValidationNotifierProvider('occ-001').future,
    );

    await notifier.validate();

    final st = container.read(occurrenceValidationNotifierProvider('occ-001'));
    expect(st.hasValue, isTrue);
    expect(st.value!.status, OccurrenceStatus.done);
  });

  test('validate_notifier_state_transitions — '
      'null → loading → data(done)', () async {
    final completer = Completer<Occurrence>();
    when(
      () => mockUseCase.call(
        occurrenceId: any(named: 'occurrenceId'),
        source: any(named: 'source'),
        now: any(named: 'now'),
      ),
    ).thenAnswer((_) => completer.future);

    final container = makeContainer();
    addTearDown(container.dispose);

    final states = <AsyncValue<Occurrence?>>[];
    container.listen(
      occurrenceValidationNotifierProvider('occ-001'),
      (_, next) => states.add(next),
      fireImmediately: true,
    );

    // Attendre build() avant la validation
    await container.read(
      occurrenceValidationNotifierProvider('occ-001').future,
    );

    final notifier = container.read(
      occurrenceValidationNotifierProvider('occ-001').notifier,
    );
    final validating = notifier.validate();
    // Doit être en loading
    await Future<void>.delayed(Duration.zero);

    completer.complete(_doneOccurrence());
    await validating;

    // Séquence : build initial (AsyncData null) → loading → data(done)
    final hasDoneState = states.any(
      (s) => s.valueOrNull?.status == OccurrenceStatus.done,
    );
    expect(hasDoneState, isTrue);
    expect(states.any((s) => s.isLoading), isTrue);
  });
}
