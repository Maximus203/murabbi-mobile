import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/core/errors/failure_message.dart';
import 'package:murabbi_mobile/domain/errors/auth_failure.dart';
import 'package:murabbi_mobile/domain/errors/collection_failure.dart';
import 'package:murabbi_mobile/domain/errors/habit_failure.dart';
import 'package:murabbi_mobile/domain/errors/occurrence_failure.dart';
import 'package:murabbi_mobile/domain/errors/prayer_failure.dart';
import 'package:murabbi_mobile/domain/errors/score_failure.dart';

void main() {
  group('FailureMessage.from — AuthFailure (#201)', () {
    test('invalidCredentials → message FR canonique', () {
      expect(
        FailureMessage.from(const AuthFailure.invalidCredentials()),
        'Email ou mot de passe incorrect.',
      );
    });

    test('invalidCredentials avec "email not confirmed" → message dédié', () {
      expect(
        FailureMessage.from(
          const AuthFailure.invalidCredentials(message: 'Email not confirmed'),
        ),
        'Confirmez votre adresse email avant de vous connecter.',
      );
    });

    test('emailAlreadyInUse', () {
      expect(
        FailureMessage.from(const AuthFailure.emailAlreadyInUse()),
        'Cet email est déjà utilisé.',
      );
    });

    test('weakPassword', () {
      expect(
        FailureMessage.from(const AuthFailure.weakPassword()),
        'Mot de passe trop faible (8 caractères minimum).',
      );
    });

    test('network', () {
      expect(
        FailureMessage.from(const AuthFailure.network()),
        'Connexion impossible — vérifie ta connexion.',
      );
    });

    test('accountDeleted (ADR-011)', () {
      expect(
        FailureMessage.from(const AuthFailure.accountDeleted()),
        'Ce compte a été supprimé. Contacte le support pour le restaurer.',
      );
    });

    test('unknown', () {
      expect(
        FailureMessage.from(const AuthFailure.unknown()),
        'Erreur inattendue. Réessaie dans un instant.',
      );
    });
  });

  group('FailureMessage.from — ScoreFailure', () {
    test('network', () {
      expect(
        FailureMessage.from(const ScoreFailure.network()),
        'Impossible de charger le score. Vérifie ta connexion.',
      );
    });

    test('notFound', () {
      expect(
        FailureMessage.from(const ScoreFailure.notFound()),
        'Score introuvable.',
      );
    });

    test('database', () {
      expect(
        FailureMessage.from(const ScoreFailure.database()),
        'Erreur lors de la récupération du score.',
      );
    });

    test('unknown', () {
      expect(
        FailureMessage.from(const ScoreFailure.unknown()),
        'Une erreur inattendue est survenue.',
      );
    });
  });

  group('FailureMessage.from — HabitFailure', () {
    test('futureLogNotAllowed', () {
      expect(
        FailureMessage.from(const HabitFailure.futureLogNotAllowed()),
        'Impossible de valider une habitude dans le futur.',
      );
    });

    test('backdateTooOld', () {
      expect(
        FailureMessage.from(const HabitFailure.backdateTooOld()),
        'Cette date est trop ancienne pour être validée (limite 8 jours).',
      );
    });

    test('database', () {
      expect(
        FailureMessage.from(const HabitFailure.database()),
        'Erreur lors de la mise à jour de l\'habitude.',
      );
    });

    test('network', () {
      expect(
        FailureMessage.from(const HabitFailure.network()),
        'Connexion impossible — vérifie ta connexion.',
      );
    });

    test('unauthorized (M3 — OwnershipGuard)', () {
      expect(
        FailureMessage.from(const HabitFailure.unauthorized()),
        'Action non autorisée. Reconnecte-toi.',
      );
    });
  });

  group('FailureMessage.from — CollectionFailure', () {
    test('network', () {
      expect(
        FailureMessage.from(const CollectionFailure.network()),
        'Impossible de charger les collections. Vérifie ta connexion.',
      );
    });

    test('database', () {
      expect(
        FailureMessage.from(const CollectionFailure.database()),
        'Erreur lors de la récupération des collections.',
      );
    });

    test('notFound', () {
      expect(
        FailureMessage.from(const CollectionFailure.notFound()),
        'Collection introuvable.',
      );
    });

    test('unknown', () {
      expect(
        FailureMessage.from(const CollectionFailure.unknown()),
        'Une erreur inattendue est survenue.',
      );
    });

    test('unauthorized (M3 — OwnershipGuard)', () {
      expect(
        FailureMessage.from(const CollectionFailure.unauthorized()),
        'Action non autorisée. Reconnecte-toi.',
      );
    });
  });

  group('FailureMessage.from — PrayerFailure', () {
    test('network', () {
      expect(
        FailureMessage.from(const PrayerFailure.network()),
        'Connexion impossible — vérifie ta connexion.',
      );
    });

    test('database', () {
      expect(
        FailureMessage.from(const PrayerFailure.database()),
        'Erreur lors de la récupération des prières.',
      );
    });

    test('malformedRow', () {
      expect(
        FailureMessage.from(const PrayerFailure.malformedRow()),
        'Données de prière invalides. Contacte le support.',
      );
    });

    test('unknownStatus', () {
      expect(
        FailureMessage.from(const PrayerFailure.unknownStatus()),
        'Statut de prière inconnu. Contacte le support.',
      );
    });

    test('settingsNotConfigured', () {
      expect(
        FailureMessage.from(const PrayerFailure.settingsNotConfigured()),
        'Configure tes réglages de prière pour commencer.',
      );
    });

    test('unknown', () {
      expect(
        FailureMessage.from(const PrayerFailure.unknown()),
        'Une erreur inattendue est survenue.',
      );
    });
  });

  group('FailureMessage.from — OccurrenceFailure', () {
    test('notFound', () {
      expect(
        FailureMessage.from(const OccurrenceFailure.notFound()),
        'Cette occurrence est introuvable.',
      );
    });

    test('alreadyFinalized', () {
      expect(
        FailureMessage.from(const OccurrenceFailure.alreadyFinalized()),
        'Cette occurrence a déjà été traitée.',
      );
    });

    test('tooLateForCatchup', () {
      expect(
        FailureMessage.from(const OccurrenceFailure.tooLateForCatchup()),
        'Trop tard pour valider cette occurrence.',
      );
    });

    test('prayerSnoozeForbidden', () {
      expect(
        FailureMessage.from(const OccurrenceFailure.prayerSnoozeForbidden()),
        'Les prières ne peuvent pas être reportées.',
      );
    });

    test('maxSnoozesReached', () {
      expect(
        FailureMessage.from(const OccurrenceFailure.maxSnoozesReached()),
        'Nombre maximum de reports atteint.',
      );
    });

    test('repository', () {
      expect(
        FailureMessage.from(const OccurrenceFailure.repository()),
        'Une erreur est survenue. Réessaie dans un instant.',
      );
    });
  });

  group('FailureMessage.from — fallback', () {
    test('Exception générique → fallback', () {
      expect(
        FailureMessage.from(Exception('boom')),
        'Une erreur inattendue est survenue.',
      );
    });

    test('Object arbitraire → fallback', () {
      expect(
        FailureMessage.from(Object()),
        'Une erreur inattendue est survenue.',
      );
    });
  });
}
