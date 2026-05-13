import 'package:equatable/equatable.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/next_prayer.dart';

/// Snapshot agrégé de l'écran d'accueil HM-01 (slice 3.A).
///
/// `nextPrayer` est nullable : on l'omet quand l'utilisateur n'a pas
/// configuré ses prières (cas `PrayerFailure.settingsNotConfigured`) — le
/// Dashboard montre alors un CTA pour ouvrir SA-02.
class DashboardState extends Equatable {
  final DateTime nowUtc;
  final NextPrayer? nextPrayer;
  final bool settingsNotConfigured;

  const DashboardState({
    required this.nowUtc,
    required this.nextPrayer,
    required this.settingsNotConfigured,
  });

  DashboardState copyWith({
    DateTime? nowUtc,
    NextPrayer? nextPrayer,
    bool? settingsNotConfigured,
    bool clearNextPrayer = false,
  }) {
    return DashboardState(
      nowUtc: nowUtc ?? this.nowUtc,
      nextPrayer: clearNextPrayer ? null : (nextPrayer ?? this.nextPrayer),
      settingsNotConfigured:
          settingsNotConfigured ?? this.settingsNotConfigured,
    );
  }

  @override
  List<Object?> get props => [nowUtc, nextPrayer, settingsNotConfigured];
}
