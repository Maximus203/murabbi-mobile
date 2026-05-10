import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/datasources/supabase/supabase_auth_data_source.dart';

/// Contract tests directs sur [SupabaseAuthDataSource].
///
/// **Objectif anti-régression** — l'observation #3 du sub-agent mobile
/// (PR #29) notait : *"Pas de test direct sur SupabaseAuthDataSource. Le
/// drift `total_points` (jamais en SQL, lu/écrit par mobile pendant des
/// semaines) est passé sans détection."*
///
/// Ces tests figent la liste exacte des colonnes que le DataSource lit et
/// écrit dans `public.users`, en miroir du schéma Supabase
/// (`murabbi-admin/supabase/migrations/20260426000000_initial_mobile_schema.sql`
/// + `20260510000000_users_deletion_requested_at_rgpd.sql`).
///
/// Les tests d'intégration "vrais" (mock du client Supabase complet via
/// les fluent builders) restent hors scope : la valeur de cette PR est de
/// figer le **contrat de colonnes**. Les méthodes `auth.*` sont déjà
/// couvertes indirectement par `auth_repository_impl_test.dart` via le
/// fake du DataSource.
void main() {
  group('SupabaseAuthDataSource — SQL columns contract', () {
    test(
      'profileColumns matches users SELECT contract (schema 2026-05-10)',
      () {
        // Source de vérité : murabbi-admin/supabase/migrations
        //   20260426000000_initial_mobile_schema.sql (users base)
        //   20260510000000_users_deletion_requested_at_rgpd.sql (RGPD col)
        //
        // `id` est volontairement absent du SELECT — il est filtré par
        // `.eq('id', user.id)` et n'a pas besoin d'être renvoyé (UserMapper
        // utilise authUser.id comme source de vérité).
        //
        // `total_points` est intentionnellement ABSENT — ce n'est PAS une
        // colonne de `public.users` (cf. PR #29). La SoT du score cumulé
        // est `user_scores.total_score` (table séparée), lue par un futur
        // `UserScoreRepository`.
        const expected = {
          'pseudo',
          'email',
          'level',
          'current_streak',
          'completion_rate',
          'deletion_requested_at',
        };

        final actual = SupabaseAuthDataSource.profileColumns
            .split(',')
            .map((c) => c.trim())
            .toSet();

        expect(
          actual,
          equals(expected),
          reason:
              'profileColumns drifted vs SQL schema. If you added/removed '
              'a column on public.users, update both the migration and '
              'this contract test.',
        );
      },
    );

    test(
      'profileColumns does NOT contain total_points (PR #29 regression guard)',
      () {
        expect(
          SupabaseAuthDataSource.profileColumns,
          isNot(contains('total_points')),
          reason:
              'PR #29 regression — total_points is NOT a column of '
              'public.users. Source of truth = user_scores.total_score.',
        );
      },
    );

    test('signUpInsertPayload contains EXACTLY the expected columns', () {
      // Source de vérité : `users` minimal row à l'inscription. `id` est
      // FK vers `auth.users.id`. Pas de `total_points`. Pas de
      // `deletion_requested_at` (NULL par défaut côté SQL).
      const expected = {
        'id',
        'pseudo',
        'email',
        'level',
        'current_streak',
        'completion_rate',
      };

      final payload = SupabaseAuthDataSource.buildSignUpInsertPayload(
        userId: '11111111-1111-1111-1111-111111111111',
        email: 'cherif@example.com',
      );

      expect(payload.keys.toSet(), equals(expected));
    });

    test(
      'signUpInsertPayload does NOT contain total_points (PR #29 regression guard)',
      () {
        final payload = SupabaseAuthDataSource.buildSignUpInsertPayload(
          userId: 'abcd-1234',
          email: 'a@b.co',
        );

        expect(
          payload.containsKey('total_points'),
          isFalse,
          reason:
              'PR #29 regression — total_points should not be inserted on '
              'public.users. Source of truth = user_scores.total_score, '
              'maintained by admin Server Actions (Q-18).',
        );
      },
    );

    test(
      'signUpInsertPayload does NOT preset deletion_requested_at (NULL by default)',
      () {
        final payload = SupabaseAuthDataSource.buildSignUpInsertPayload(
          userId: 'abcd-1234',
          email: 'a@b.co',
        );

        expect(
          payload.containsKey('deletion_requested_at'),
          isFalse,
          reason:
              'deletion_requested_at must default to NULL via SQL — never '
              'set explicitly at signup, otherwise soft-delete logic '
              '(ADR-011) breaks.',
        );
      },
    );

    test(
      'signUpInsertPayload uses correct default values (level=aspirant, streak=0)',
      () {
        final payload = SupabaseAuthDataSource.buildSignUpInsertPayload(
          userId: 'uid-x',
          email: 'a@b.co',
        );

        expect(payload['id'], 'uid-x');
        expect(payload['email'], 'a@b.co');
        expect(payload['level'], 'aspirant');
        expect(payload['current_streak'], 0);
        expect(payload['completion_rate'], 0);
        // pseudo is auto-generated (Q-18 — "Anonyme #<tail>")
        expect(payload['pseudo'], isA<String>());
        expect(payload['pseudo'] as String, startsWith('Anonyme #'));
      },
    );
  });

  group('SupabaseAuthDataSource — auto pseudo generation (Q-18)', () {
    test('autoPseudo uses last 4 chars when id is long enough', () {
      final pseudo =
          SupabaseAuthDataSource.buildSignUpInsertPayload(
                userId: '11111111-1111-1111-1111-1111111abcd',
                email: 'a@b.co',
              )['pseudo']
              as String;

      expect(pseudo, 'Anonyme #abcd');
    });

    test('autoPseudo uses full id when shorter than 4 chars', () {
      final pseudo =
          SupabaseAuthDataSource.buildSignUpInsertPayload(
                userId: 'xy',
                email: 'a@b.co',
              )['pseudo']
              as String;

      expect(pseudo, 'Anonyme #xy');
    });

    test('autoPseudo is deterministic for the same id', () {
      final p1 = SupabaseAuthDataSource.buildSignUpInsertPayload(
        userId: 'same-id-9999',
        email: 'a@b.co',
      )['pseudo'];
      final p2 = SupabaseAuthDataSource.buildSignUpInsertPayload(
        userId: 'same-id-9999',
        email: 'other@example.com',
      )['pseudo'];

      expect(p1, equals(p2));
    });
  });

  group(
    'SupabaseAuthDataSource — soft-delete update payload contract (ADR-011)',
    () {
      test(
        'buildDeleteAccountUpdatePayload sets ONLY deletion_requested_at',
        () {
          final payload =
              SupabaseAuthDataSource.buildDeleteAccountUpdatePayload();

          expect(
            payload.keys.toSet(),
            equals({'deletion_requested_at'}),
            reason:
                'deleteAccount is a soft-delete (ADR-011) — must set only '
                'deletion_requested_at, no other columns touched.',
          );
        },
      );

      test(
        'buildDeleteAccountUpdatePayload value is a parseable ISO-8601 timestamp',
        () {
          final payload =
              SupabaseAuthDataSource.buildDeleteAccountUpdatePayload();
          final raw = payload['deletion_requested_at'] as String;

          expect(() => DateTime.parse(raw), returnsNormally);
        },
      );
    },
  );
}
