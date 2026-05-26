import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/prayer_status_visuals.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Bottom sheet de sélection d'un [PrayerStatus] (SA-01 — Q-21 option A2).
///
/// Présente les 5 statuts en boutons explicites pour éviter le cycling
/// ambigu sur la row. Renvoie le statut tapé via `Navigator.pop(status)` ;
/// renvoie `null` si l'utilisateur ferme par scrim/back.
class StatusPickerBottomSheet extends StatelessWidget {
  final String prayerLabel;
  final PrayerStatus current;

  const StatusPickerBottomSheet({
    super.key,
    required this.prayerLabel,
    required this.current,
  });

  /// Ordre d'affichage explicite des statuts dans le bottom sheet —
  /// **ne pas** s'appuyer sur `PrayerStatus.values` (l'ordre de
  /// déclaration de l'enum changerait silencieusement l'UI). Cf. review
  /// Copilot PR #38.
  ///
  /// Ordre choisi pour l'UX : statuts positifs en premier (onTime → late
  /// → makeup → missed) puis "non priée" comme reset. La sélection
  /// courante est mise en évidence via la coche.
  static const List<PrayerStatus> displayOrder = [
    PrayerStatus.onTime,
    PrayerStatus.late,
    PrayerStatus.makeup,
    PrayerStatus.missed,
    PrayerStatus.pending,
  ];

  /// Ouvre le sheet. Le résultat est le statut tapé (ou `null` si fermé sans
  /// sélection).
  static Future<PrayerStatus?> show(
    BuildContext context, {
    required String prayerLabel,
    required PrayerStatus current,
  }) {
    return showModalBottomSheet<PrayerStatus>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      builder: (ctx) =>
          StatusPickerBottomSheet(prayerLabel: prayerLabel, current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s5,
          AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prayerLabel, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.s4),
            for (final status in displayOrder)
              _StatusTile(
                status: status,
                selected: status == current,
                onTap: () => Navigator.of(context).pop(status),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final PrayerStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusTile({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = PrayerStatusVisuals.color(status);
    return Semantics(
      button: true,
      selected: selected,
      label: PrayerStatusVisuals.label(status),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s3,
            horizontal: AppSpacing.s2,
          ),
          child: Row(
            children: [
              Icon(PrayerStatusVisuals.icon(status), size: AppIconSize.rg, color: color),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  PrayerStatusVisuals.label(status),
                  style: AppTypography.body,
                ),
              ),
              if (selected)
                const Icon(
                  LucideIcons.check,
                  size: AppIconSize.md,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
