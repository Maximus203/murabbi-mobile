import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:murabbi_mobile/data/repositories/auth_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/repositories/auth_repository.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/router/app_router.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';
import 'package:murabbi_mobile/services/onboarding_flag_storage.dart';
import '../../helpers/test_uuids.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeOnboardingFlagStorage extends Fake implements OnboardingFlagStorage {
  final bool _seen;
  _FakeOnboardingFlagStorage({required bool seen}) : _seen = seen;

  @override
  Future<bool> isCompleted() async => _seen;
}

final _authedUser = User(
  id: UserId(kUserIdAlpha),
  pseudo: Pseudonym('Ibrahim'),
  email: NonEmptyString('ibrahim@example.com'),
  createdAt: DateTime(2026, 1, 1),
  level: Level.aspirant,
);

void main() {
  late _MockAuthRepository auth;

  setUp(() {
    auth = _MockAuthRepository();
  });

  Widget buildApp({required bool onboardingSeen}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        onboardingFlagStorageProvider.overrideWithValue(
          _FakeOnboardingFlagStorage(seen: onboardingSeen),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: ref.watch(appRouterProvider),
        ),
      ),
    );
  }

  testWidgets(
    'shell renders no bottom nav while auth is loading',
    (tester) async {
      // Auth démarre en loading (Completer jamais résolu pendant ce test).
      when(() => auth.authStateChanges)
          .thenAnswer((_) => const Stream<User?>.empty());
      when(() => auth.getCurrentUser())
          .thenAnswer((_) => Completer<User?>().future);

      await tester.pumpWidget(buildApp(onboardingSeen: true));
      await tester.pump(); // 1 frame — auth toujours loading

      // GoRouter redirige vers /splash ; le shell ne doit pas être rendu.
      expect(find.byType(AppBottomNav), findsNothing);
    },
  );

  testWidgets(
    'shell shows bottom nav once auth resolves with user',
    (tester) async {
      when(() => auth.authStateChanges)
          .thenAnswer((_) => Stream.value(_authedUser));
      when(() => auth.getCurrentUser()).thenAnswer((_) async => _authedUser);

      await tester.pumpWidget(buildApp(onboardingSeen: true));
      // Pompe plusieurs frames sans pumpAndSettle : le dashboard tente d'accéder
      // à Supabase (non initialisé en test) et crée des futures en suspens.
      // On n'a besoin que que le shell soit construit — ce qui arrive dès que
      // auth + onboarding sont résolus et que GoRouter a redirigé vers /home.
      for (var i = 0; i < 10; i++) {
        await tester.pump();
      }

      // Auth résolu + onboarding vu → /home → shell visible avec AppBottomNav.
      expect(find.byType(AppBottomNav), findsOneWidget);
    },
  );
}
