import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/domain/value_objects/user_id.dart';

abstract interface class ScoreRepository {
  Future<UserScore> getUserScore(UserId userId);
  Future<List<UserScore>> getLeaderboard({required int limit});
}
