import 'dart:io';

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
        //
        // `pseudo_full` est intentionnellement ABSENT — colonne GENERATED
        // STORED (admin#125) non encore migrée en prod. UserMapper la gère
        // null-safe. À réintégrer quand la migration admin sera appliquée.
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

    test(
      'signUpInsertPayload NEVER contains pseudo_full or pseudo_suffix (#168)',
      () {
        // Issue #168 / admin#125 — `pseudo_full` est GENERATED STORED
        // (Postgres calcule la valeur), `pseudo_suffix` est rempli par un
        // trigger SECURITY DEFINER côté admin. Les écrire depuis le mobile
        // serait rejeté (cannot insert into generated column / RLS).
        final payload = SupabaseAuthDataSource.buildSignUpInsertPayload(
          userId: '11111111-1111-1111-1111-111111111111',
          email: 'cherif@example.com',
          displayName: 'Cherif',
        );
        expect(payload.containsKey('pseudo_full'), isFalse);
        expect(payload.containsKey('pseudo_suffix'), isFalse);
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
    'SupabaseAuthDataSource — signUp source contract (trigger-driven creation)',
    () {
      // Contract garde-fou : depuis murabbi-admin migration
      //   20260513000000_users_rls_hardening
      // la création de `public.users` est faite par un trigger SECURITY
      // DEFINER côté backend (`on_auth_user_created`). Le mobile ne doit
      // PLUS faire d'INSERT explicite sur `users` dans `signUp`, sinon :
      //   - avec email confirmation ON : auth.uid() null → RLS reject → exception
      //   - sans email confirmation   : conflit PK (trigger a déjà inséré)
      //
      // Test source-level (cohérent avec l'approche des contract tests
      // SQL côté admin) : on lit le fichier .dart et on cherche un
      // pattern interdit dans la méthode signUp.

      final sourceFile = File(
        'lib/data/datasources/supabase/supabase_auth_data_source.dart',
      );
      final source = sourceFile.readAsStringSync();

      // Extrait la méthode signUp pour scoper les assertions (sinon
      // deleteAccount qui fait `.from('users').update(...)` produirait
      // un faux positif).
      final signUpMatch = RegExp(
        r'Future<AuthMaps>\s+signUp\([^)]*\)\s+async\s*\{(.*?)\n\s\s\}',
        dotAll: true,
      ).firstMatch(source);

      test('source file is readable (sanity check)', () {
        expect(
          sourceFile.existsSync(),
          isTrue,
          reason: 'supabase_auth_data_source.dart not found at expected path',
        );
        expect(source, contains('class SupabaseAuthDataSource'));
      });

      test('signUp method body is locatable for scoped assertions', () {
        expect(
          signUpMatch,
          isNotNull,
          reason:
              'Could not extract signUp method body. If the method signature '
              'changed, update the regex above.',
        );
      });

      test(
        'signUp does NOT call .from(\'users\').insert(...) — trigger handles it',
        () {
          final body = signUpMatch?.group(1) ?? '';
          expect(
            body,
            isNot(matches(RegExp(r"\.from\(\s*'users'\s*\)\s*\.insert\("))),
            reason:
                'signUp must not INSERT into public.users — the backend '
                'trigger `on_auth_user_created` (admin migration '
                '20260513000000_users_rls_hardening) creates the profile. '
                'A client INSERT will break signup once Confirm email is '
                'enabled (auth.uid() is null at signUp → RLS reject).',
          );
        },
      );

      test(
        'signUp still uses buildSignUpInsertPayload for profileOverride (anti-drift)',
        () {
          final body = signUpMatch?.group(1) ?? '';
          expect(
            body,
            contains('buildSignUpInsertPayload'),
            reason:
                'buildSignUpInsertPayload remains the source of truth for '
                'the default profile values exposed to UI immediately after '
                'signUp. Its columns mirror the backend trigger.',
          );
        },
      );

      test('signUp references the trigger in a comment (auditability)', () {
        final body = signUpMatch?.group(1) ?? '';
        expect(
          body.toLowerCase(),
          contains('on_auth_user_created'),
          reason:
              'The comment in signUp must reference the backend trigger so '
              'future readers understand why no client INSERT is done.',
        );
      });
    },
  );

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

  group(
    'SupabaseAuthDataSource — authStateChanges filtre tokenRefreshed (Bug S-2)',
    () {
      // Source-level contract : garantit que le stream filtre les événements
      // TOKEN_REFRESHED pour ne pas déclencher de SELECT inutile sur
      // public.users lors des refreshes JWT silencieux (~toutes les 60 min).
      // Un SELECT qui échoue à ce moment déconnecte l'utilisateur à tort.
      final sourceFile = File(
        'lib/data/datasources/supabase/supabase_auth_data_source.dart',
      );
      final source = sourceFile.readAsStringSync();

      test('authStateChanges contient un filtre sur tokenRefreshed', () {
        expect(
          source,
          contains('tokenRefreshed'),
          reason:
              'authStateChanges doit filtrer AuthChangeEvent.tokenRefreshed. '
              'Sans ce filtre, chaque refresh JWT silencieux (~60 min) '
              'déclenche un SELECT sur public.users. Si ce SELECT échoue '
              '(réseau, timeout), le stream émet une erreur qui déconnecte '
              "l'utilisateur malgré une session JWT valide (Bug S-2).",
        );
      });
    },
  );
}
