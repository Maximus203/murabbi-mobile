import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/data/mappers/user_score_mapper.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';

/// Mapper pur — rows Supabase (`users` + vue `weekly_leaderboard`) ↔
/// entité [UserScore] (issue #6, Phase 5).
void main() {
  group('UserScoreMapper.fromRow', () {
    test('mappe un score complet avec rang', () {
      final row = {
        'user_id': 'u-1',
        'total_points': 12000,
        'weekly_score': 240,
        'rank': 3,
        'pseudo': 'Ibrahim',
      };

      final s = UserScoreMapper.fromRow(row);

      expect(s.userId.value, 'u-1');
      expect(s.totalPoints, 12000);
      expect(s.weeklyPoints, 240);
      expect(s.weeklyRank, 3);
      expect(s.currentLevel, Level.murid); // 12000 ≥ 10000
      expect(s.pseudo, 'Ibrahim');
    });

    test('défaut rang 1 et points 0 quand colonnes absentes', () {
      final row = {'user_id': 'u-2'};

      final s = UserScoreMapper.fromRow(row);

      expect(s.totalPoints, 0);
      expect(s.weeklyPoints, 0);
      expect(s.weeklyRank, 1);
      expect(s.currentLevel, Level.aspirant);
      expect(s.pseudo, isNull);
    });

    test('le niveau est dérivé des points totaux', () {
      final row = {
        'user_id': 'u-3',
        'total_points': 300000,
        'weekly_score': 0,
        'rank': 50,
        'pseudo': 'Khadija',
      };

      expect(UserScoreMapper.fromRow(row).currentLevel, Level.murabbi);
    });

    test('lit le pseudo quand présent dans la row', () {
      final row = {
        'user_id': 'u-4',
        'total_points': 5000,
        'weekly_score': 100,
        'rank': 2,
        'pseudo': 'Fatima',
      };

      expect(UserScoreMapper.fromRow(row).pseudo, 'Fatima');
    });

    test('pseudo est nul quand absent de la row', () {
      final row = {'user_id': 'u-5', 'total_points': 0, 'rank': 1};

      expect(UserScoreMapper.fromRow(row).pseudo, isNull);
    });

    // Q-F Option A — colonne previous_week_rank (v1.2.1)
    test('previousWeekRank mappé quand présent', () {
      final row = {
        'user_id': 'u-6',
        'total_points': 5000,
        'weekly_score': 100,
        'rank': 5,
        'previous_week_rank': 7,
      };

      final s = UserScoreMapper.fromRow(row);

      expect(s.previousWeekRank, 7);
      expect(s.rankMovement, 2); // 7 - 5 = monté de 2 places
    });

    test('previousWeekRank null quand absent (première semaine)', () {
      final row = {
        'user_id': 'u-7',
        'total_points': 0,
        'weekly_score': 0,
        'rank': 1,
      };

      final s = UserScoreMapper.fromRow(row);

      expect(s.previousWeekRank, isNull);
      expect(s.rankMovement, isNull);
    });

    test('previousWeekRank null explicite mappé en null', () {
      final row = {
        'user_id': 'u-8',
        'total_points': 0,
        'weekly_score': 0,
        'rank': 1,
        'previous_week_rank': null,
      };

      expect(UserScoreMapper.fromRow(row).previousWeekRank, isNull);
    });
  });
}
