enum Level {
  aspirant,
  murid,
  salik,
  mujahid,
  wali,
  murabbi;

  /// Seuils d'entrée par niveau — verrouillés par Q-10b
  /// (`murabbi-admin/docs/decisions/product_decisions_v1.md`).
  /// Calibrage : Murabbi atteignable en ≈10 ans à 60 pts/j.
  static const Map<Level, int> thresholds = {
    Level.aspirant: 0,
    Level.murid: 10000,
    Level.salik: 30000,
    Level.mujahid: 70000,
    Level.wali: 150000,
    Level.murabbi: 300000,
  };

  /// Objectif quotidien (points/jour) par niveau — verrouillé par Q-10c.
  /// Croît avec le niveau : l'utilisateur engagé doit fournir plus à mesure
  /// qu'il progresse.
  static const Map<Level, int> _dailyGoals = {
    Level.aspirant: 30,
    Level.murid: 45,
    Level.salik: 60,
    Level.mujahid: 75,
    Level.wali: 90,
    Level.murabbi: 105,
  };

  int get threshold => thresholds[this]!;

  int get dailyGoal => _dailyGoals[this]!;

  static Level fromPoints(int totalPoints) {
    final sorted = Level.values.reversed.toList();
    for (final level in sorted) {
      if (totalPoints >= level.threshold) return level;
    }
    return Level.aspirant;
  }
}
