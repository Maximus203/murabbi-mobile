enum Level {
  aspirant,
  murid,
  salik,
  mujahid,
  wali,
  murabbi;

  static const Map<Level, int> thresholds = {
    Level.aspirant: 0,
    Level.murid: 1000,
    Level.salik: 5000,
    Level.mujahid: 15000,
    Level.wali: 40000,
    Level.murabbi: 100000,
  };

  /// Daily point target for this level. Increases at each palier (Q-10 B).
  static const Map<Level, int> _dailyGoals = {
    Level.aspirant: 60,
    Level.murid: 80,
    Level.salik: 100,
    Level.mujahid: 120,
    Level.wali: 150,
    Level.murabbi: 200,
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
