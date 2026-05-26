import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/repositories/daily_summary_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/niyyah_suggestion_repository_provider.dart';
import 'package:murabbi_mobile/data/repositories/score_repository_provider.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/user.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/value_objects/non_empty_string.dart';
import 'package:murabbi_mobile/domain/value_objects/pseudonym.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_clock_provider.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/salat/providers/current_user_provider.dart';
import 'package:murabbi_mobile/services/prayer/prayer_times_providers.dart';
import '../../../../helpers/test_uuids.dart';

/// Contract tests sur la réactivité de [DashboardNotifier] au changement
/// de session utilisateur.
///
/// **Contexte** (audit sécurité 2026-05-26) : [DashboardNotifier.build()]
/// utilisait `ref.read(currentUserProvider)` — `ref.read` ne crée aucune
/// dépendance réactive. Le notifier ne se reconstruisait donc pas au signOut,
/// laissant les données de l'utilisateur A visibles pour l'utilisateur B
/// (fuite inter-sessions — vecteur CRITIQUE).
///
/// **Fix** : remplacer `ref.read` par `ref.watch` (ligne 34 de
/// `dashboard_notifier.dart`).
///
/// Ces tests sont des **tests d'intégration légers** : ils n'utilisent pas
/// Supabase (tous les repos lèvent des erreurs capturées par les try/catch
/// internes du notifier) mais exercent le graphe complet de providers Riverpod.
void main() {
  final fixedNow = DateTime.utc(2026, 5, 26, 12);

  /// Utilisateur A avec streak = 7 — observable via [DashboardState.globalStreak].
  final userA = User(
    id: UserId(kUserIdAlpha),
    pseudo: Pseudonym('Cherif'),
    email: NonEmptyString('cherif@example.com'),
    createdAt: DateTime(2026, 1, 1),
    level: Level.aspirant,
    currentStreak: 7,
  );

  /// Crée un [ProviderContainer] minimal pour [dashboardNotifierProvider].
  ///
  /// [userSource] : [StateProvider] mutable utilisé comme source pour
  /// [currentUserProvider] — permet de simuler un changement de session
  /// sans dépendance à Supabase.
  ///
  /// Tous les repositories lèvent [StateError] → capturé par les try/catch
  /// du notifier → valeurs de fallback (null / 0.0) sans exception visible.
  ProviderContainer makeContainer({
    required StateProvider<User?> userSource,
  }) {
    final c = ProviderContainer(
      overrides: [
        // Horloge figée — tests déterministes.
        dashboardClockProvider.overrideWithValue(() => fixedNow),
        // currentUserProvider dérivé du StateProvider mutable.
        currentUserProvider.overrideWith((ref) => ref.watch(userSource)),
        // Repos DB : lèvent des erreurs capturées par les try/catch internes.
        // DashboardNotifier absorbe gracieusement les exceptions et retourne
        // des valeurs de fallback (null / 0.0).
        scoreRepositoryProvider.overrideWith(
          (ref) => throw StateError('no score db in test'),
        ),
        dailySummaryRepositoryProvider.overrideWith(
          (ref) => throw StateError('no summary db in test'),
        ),
        niyyahRepositoryProvider.overrideWith(
          (ref) => throw StateError('no niyyah db in test'),
        ),
        niyyahSuggestionRepositoryProvider.overrideWith(
          (ref) => throw StateError('no suggestion db in test'),
        ),
        // Les horaires de prière ne sont pas configurés — cas de test sans
        // PrayerSettings. _loadPrayer capture PrayerSettingsNotConfiguredFailure.
        getPrayerTimesUseCaseProvider.overrideWith(
          (ref) => Future.error(const PrayerSettingsNotConfiguredFailure()),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('DashboardNotifier — réactivité auth (anti-fuite inter-sessions)', () {
    test(
      'build() se reconstruit quand currentUserProvider passe de User→null (ref.watch)',
      () async {
        // Ce test est RED tant que build() utilise ref.read(currentUserProvider).
        // ref.read ne crée pas de dépendance réactive → le notifier ne se
        // reconstruit pas au signOut → state1.globalStreak (= 7) reste figé.
        //
        // Après le fix (ref.watch), currentUserProvider devient une dépendance
        // réactive → build() est relancé quand user passe null → globalStreak = 0.
        final userSource = StateProvider<User?>((ref) => userA);
        final container = makeContainer(userSource: userSource);

        // Build #1 — utilisateur A connecté, streak = 7.
        final state1 = await container.read(dashboardNotifierProvider.future);
        expect(state1.globalStreak, 7);

        // Simule une déconnexion : currentUserProvider → null.
        container.read(userSource.notifier).state = null;
        await Future<void>.delayed(Duration.zero);

        // Build #2 attendu (avec ref.watch) : globalStreak doit être 0.
        // Sans le fix (ref.read) : globalStreak reste 7 → données de A pour B.
        final state2 = await container.read(dashboardNotifierProvider.future);
        expect(
          state2.globalStreak,
          0,
          reason:
              'DashboardNotifier.build() doit utiliser ref.watch(currentUserProvider) '
              'pour réagir au changement de session. Avec ref.read, le provider '
              'ne se reconstruit pas au signOut → données de l\'utilisateur A '
              'visibles par l\'utilisateur B (fuite inter-sessions critique).',
        );
      },
    );

    test(
      'globalStreak est 0 quand currentUserProvider est null dès le build initial',
      () async {
        // Vérifie que DashboardNotifier gère user=null sans exception.
        final userSource = StateProvider<User?>((ref) => null);
        final container = makeContainer(userSource: userSource);

        final state = await container.read(dashboardNotifierProvider.future);
        expect(state.globalStreak, 0);
        expect(state.userScore, isNull);
      },
    );
  });
}
