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

  /// Libellés FR affichables (HM-01 score card) — translittérations
  /// alignées sur le glossaire produit.
  static const Map<Level, String> _labels = {
    Level.aspirant: 'Aspirant',
    Level.murid: 'Murīd',
    Level.salik: 'Sālik',
    Level.mujahid: 'Mujāhid',
    Level.wali: 'Walī',
    Level.murabbi: 'Murabbī',
  };

  /// Descriptions FR courtes affichées sur l'overlay LEVEL-UP (issue #7).
  static const Map<Level, String> _descriptions = {
    Level.aspirant: 'Tu poses les premières pierres de ta pratique.',
    Level.murid: 'Tu t\'engages sur le chemin avec constance.',
    Level.salik: 'Tu avances avec discipline et régularité.',
    Level.mujahid: 'Ton effort intérieur devient une force.',
    Level.wali: 'Ta proximité se traduit dans chaque acte.',
    Level.murabbi: 'Tu guides désormais autant que tu progresses.',
  };

  int get threshold => thresholds[this]!;

  int get dailyGoal => _dailyGoals[this]!;

  /// Libellé FR affichable de ce niveau.
  String get label => _labels[this]!;

  /// Description FR courte de ce niveau (overlay LEVEL-UP).
  String get description => _descriptions[this]!;

  /// Palier immédiatement supérieur, ou `null` si c'est le dernier niveau.
  Level? get nextLevel {
    final idx = Level.values.indexOf(this);
    if (idx == Level.values.length - 1) return null;
    return Level.values[idx + 1];
  }

  /// Progression [0..1] de [totalPoints] entre le seuil de ce niveau et
  /// celui du palier suivant. Le dernier niveau renvoie toujours `1.0`.
  double progressToNext(int totalPoints) {
    final next = nextLevel;
    if (next == null) return 1.0;
    final span = next.threshold - threshold;
    if (span <= 0) return 1.0;
    final done = (totalPoints - threshold) / span;
    return done.clamp(0.0, 1.0);
  }

  static Level fromPoints(int totalPoints) {
    final sorted = Level.values.reversed.toList();
    for (final level in sorted) {
      if (totalPoints >= level.threshold) return level;
    }
    return Level.aspirant;
  }

  /// Parse l'enum string verrouillé Q-18 (`users.level` côté admin).
  /// Rejette toute valeur hors des 6 niveaux par `ArgumentError`.
  static Level fromString(String value) {
    for (final level in Level.values) {
      if (level.name == value) return level;
    }
    throw ArgumentError.value(value, 'level', 'unknown level');
  }

  /// Parse le niveau depuis l'entier DB Supabase (`user_scores.level int`).
  /// Mapping : 1 = aspirant … 6 = murabbi (index décalé de 1).
  /// Rejette toute valeur hors [1, 6] par `ArgumentError`.
  static Level fromInt(int value) {
    if (value >= 1 && value <= Level.values.length) {
      return Level.values[value - 1];
    }
    throw ArgumentError.value(
      value,
      'level',
      'level must be between 1 and ${Level.values.length}',
    );
  }
}
