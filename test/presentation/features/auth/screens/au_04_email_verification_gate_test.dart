import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/auth/screens/au_04_email_verification_gate.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  final pendingUser = User(
    id: UserId('uuid-pending'),
    pseudo: NonEmptyString('Anonyme #ab12'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026, 5, 7),
    level: Level.aspirant,
  );

  setUp(() {
    repo = MockAuthRepository();
    when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => const Stream<User?>.empty());
    when(() => repo.getCurrentUser()).thenAnswer((_) async => pendingUser);
    // Par defaut, refreshSession renvoie le pendingUser (non confirme).
    when(() => repo.refreshSession()).thenAnswer((_) async => pendingUser);
  });

  Widget makeApp() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Au04EmailVerificationGate(
          onContinue: () {},
          onChangeEmail: () {},
        ),
      ),
    );
  }

  testWidgets(
    'tapping "Renvoyer l\'email" calls repo.resendVerificationEmail (NOT sendPasswordResetEmail)',
    (tester) async {
      when(
        () => repo.resendVerificationEmail(email: 'cherif@example.com'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(makeApp());
      // Drain initial getCurrentUser without advancing past le Timer 5s.
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Renvoyer l\'email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      verify(
        () => repo.resendVerificationEmail(email: 'cherif@example.com'),
      ).called(1);
      verifyNever(
        () => repo.sendPasswordResetEmail(email: any(named: 'email')),
      );
      expect(find.textContaining('Email renvoyé'), findsOneWidget);

      // Cleanup pour eviter que le Timer.periodic ne fire post-test.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'polls refreshSession periodiquement (Q2-C auto-detect email confirme)',
    (tester) async {
      await tester.pumpWidget(makeApp());
      // Drain initial getCurrentUser sans declencher le timer.
      await tester.pump(const Duration(milliseconds: 50));
      // Avance >= 1 tick du timer (5s) -> refreshSession doit etre appele.
      await tester.pump(const Duration(seconds: 6));

      verify(() => repo.refreshSession()).called(greaterThanOrEqualTo(1));

      // Cleanup pour annuler le Timer.periodic post-test.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'auto-quitte le gate quand refreshSession revele un user confirme (onContinue appelee)',
    (tester) async {
      var continueCalls = 0;

      // Premier refreshSession : pas encore confirme. Deuxieme : confirme
      // (emailConfirmedAt non null -> isEmailVerified == true).
      final confirmedUser = User(
        id: pendingUser.id,
        pseudo: pendingUser.pseudo,
        email: pendingUser.email,
        createdAt: pendingUser.createdAt,
        level: pendingUser.level,
        emailConfirmedAt: DateTime(2026, 5, 8),
      );
      var refreshCalls = 0;
      when(() => repo.refreshSession()).thenAnswer((_) async {
        refreshCalls += 1;
        return refreshCalls >= 2 ? confirmedUser : pendingUser;
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Au04EmailVerificationGate(
              onContinue: () => continueCalls += 1,
              onChangeEmail: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Premier tick : encore pendingUser, on reste sur le gate.
      await tester.pump(const Duration(seconds: 6));
      // Deuxieme tick : confirmedUser arrive, le gate doit appeler onContinue.
      await tester.pump(const Duration(seconds: 6));
      // Laisse les microtasks finir (refreshSession est async).
      await tester.pump(const Duration(milliseconds: 50));

      expect(continueCalls, greaterThanOrEqualTo(1));

      // Cleanup pour annuler le Timer.periodic post-test.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
