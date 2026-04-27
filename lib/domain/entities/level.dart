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

  int get threshold => thresholds[this]!;

  static Level fromPoints(int totalPoints) {
    final sorted = Level.values.reversed.toList();
    for (final level in sorted) {
      if (totalPoints >= level.threshold) return level;
    }
    return Level.aspirant;
  }
}
