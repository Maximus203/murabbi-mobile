import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/domain/entities/level.dart';
import 'package:murabbi_mobile/domain/entities/niyyah_display_item.dart';
import 'package:murabbi_mobile/domain/entities/user_score.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/next_prayer.dart';

/// Snapshot agrégé de l'écran d'accueil HM-01 (slice 3.A + 5.F).
///
/// `nextPrayer` est nullable : on l'omet quand l'utilisateur n'a pas
/// configuré ses prières (cas `PrayerFailure.settingsNotConfigured`) — le
/// Dashboard montre alors un CTA pour ouvrir SA-02.
///
/// `userScore` et `globalStreak` sont ajoutés en slice 5.F pour afficher
/// le score hebdomadaire, le niveau et la série globale.
class DashboardState extends Equatable {
  final DateTime nowUtc;
  final NextPrayer? nextPrayer;
  final bool settingsNotConfigured;

  /// Score de l'utilisateur — null si non chargé ou utilisateur non connecté.
  final UserScore? userScore;

  /// Nombre de jours consécutifs de la série globale — 0 par défaut.
  final int globalStreak;

  /// Taux de complétion journalier (0.0 à 100.0) depuis `daily_summaries`.
  /// 0.0 si la table n'a pas encore de ligne pour aujourd'hui.
  final double dailyCompletionRate;

  /// Niyyah à afficher : personnelle ou suggestion système.
  /// null si non encore chargé.
  final NiyyahDisplayItem? niyyahToday;

  const DashboardState({
    required this.nowUtc,
    required this.nextPrayer,
    required this.settingsNotConfigured,
    this.userScore,
    this.globalStreak = 0,
    this.dailyCompletionRate = 0.0,
    this.niyyahToday,
  });

  DashboardState copyWith({
    DateTime? nowUtc,
    NextPrayer? nextPrayer,
    bool? settingsNotConfigured,
    UserScore? userScore,
    int? globalStreak,
    double? dailyCompletionRate,
    NiyyahDisplayItem? niyyahToday,
  }) {
    return DashboardState(
      nowUtc: nowUtc ?? this.nowUtc,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      settingsNotConfigured:
          settingsNotConfigured ?? this.settingsNotConfigured,
      userScore: userScore ?? this.userScore,
      globalStreak: globalStreak ?? this.globalStreak,
      dailyCompletionRate: dailyCompletionRate ?? this.dailyCompletionRate,
      niyyahToday: niyyahToday ?? this.niyyahToday,
    );
  }

  /// Niveau courant — dérivé de [userScore] ou [Level.aspirant] par défaut.
  Level get currentLevel => userScore?.currentLevel ?? Level.aspirant;

  /// Points hebdomadaires — 0 si aucun score.
  int get weeklyPoints => userScore?.weeklyPoints ?? 0;

  @override
  List<Object?> get props => [
    nowUtc,
    nextPrayer,
    settingsNotConfigured,
    userScore,
    globalStreak,
    dailyCompletionRate,
    niyyahToday,
  ];
}
