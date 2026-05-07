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
}
