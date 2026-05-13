import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/auth/providers/auth_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_notifier.dart';
import 'package:murabbi_mobile/presentation/features/dashboard/providers/dashboard_state.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';

/// HM-01 — Écran d'accueil Murabbi (slice 3.A).
///
/// Agrège : salutation, date du jour, prochaine prière, placeholders
/// habitudes / niyyah / streak (slices à venir 3.D/3.E/scoring), et
/// barre de navigation principale.
class Hm01DashboardScreen extends ConsumerWidget {
  final ValueChanged<AppBottomNavTab> onTabSelected;
  final VoidCallback onConfigurePrayers;
  final VoidCallback onOpenSalat;
  final VoidCallback? onSignOut;

  const Hm01DashboardScreen({
    super.key,
    required this.onTabSelected,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardNotifierProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final pseudo = user?.pseudo.value ?? 'Murabbi';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      bottomNavigationBar: AppBottomNav(
        active: AppBottomNavTab.home,
        onTabSelected: onTabSelected,
      ),
      body: SafeArea(
        bottom: false,
        child: dashboard.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (e, _) => _GenericError(message: e.toString()),
          data: (data) => _DashboardBody(
            data: data,
            pseudo: pseudo,
            onConfigurePrayers: onConfigurePrayers,
            onOpenSalat: onOpenSalat,
            onSignOut: onSignOut,
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardState data;
  final String pseudo;
  final VoidCallback onConfigurePrayers;
  final VoidCallback onOpenSalat;
  final VoidCallback? onSignOut;

  const _DashboardBody({
    required this.data,
    required this.pseudo,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final local = data.nowUtc.toLocal();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s6,
        AppSpacing.s5,
        AppSpacing.s5,
      ),
      children: [
        // ── En-tête ────────────────────────────────────────────────
        Text(
          'AS-SALĀMU ʿALAYKUM',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(pseudo, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.s1),
        Text(
          _frenchDate(local),
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.s6),

        // ── Prochaine prière ───────────────────────────────────────
        _NextPrayerCard(
          state: data,
          onConfigurePrayers: onConfigurePrayers,
          onOpenSalat: onOpenSalat,
        ),
        const SizedBox(height: AppSpacing.s4),

        // ── Placeholders à venir ───────────────────────────────────
        const _PlaceholderCard(
          icon: LucideIcons.listChecks,
          title: 'Habitudes du jour',
          subtitle: 'Disponible bientôt (slice 3.D).',
        ),
        const SizedBox(height: AppSpacing.s3),
        const _PlaceholderCard(
          icon: LucideIcons.heartPulse,
          title: 'Niyyah du jour',
          subtitle: 'Disponible bientôt.',
        ),
        const SizedBox(height: AppSpacing.s3),
        const _PlaceholderCard(
          icon: LucideIcons.flame,
          title: 'Série globale',
          subtitle: 'Disponible quand les habitudes seront activées.',
        ),

        if (onSignOut != null) ...[
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: 'Se déconnecter',
            onPressed: onSignOut,
            variant: AppButtonVariant.ghost,
          ),
        ],
      ],
    );
  }

  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  static const _weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  static String _frenchDate(DateTime local) {
    final wd = _weekdays[local.weekday - 1];
    final m = _months[local.month - 1];
    return '$wd ${local.day} $m';
  }
}

class _NextPrayerCard extends StatelessWidget {
  final DashboardState state;
  final VoidCallback onConfigurePrayers;
  final VoidCallback onOpenSalat;

  const _NextPrayerCard({
    required this.state,
    required this.onConfigurePrayers,
    required this.onOpenSalat,
  });

  static const Map<String, String> _names = {
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  @override
  Widget build(BuildContext context) {
    if (state.settingsNotConfigured) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Configurez vos prières', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Indiquez votre position et votre méthode pour afficher les '
              'horaires précis.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppButton(label: 'Configurer', onPressed: onConfigurePrayers),
          ],
        ),
      );
    }

    final next = state.nextPrayer;
    if (next == null) {
      return const AppCard(
        child: Text(
          'Horaires indisponibles pour le moment.',
          style: AppTypography.body,
        ),
      );
    }

    final local = next.timeUtc.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final label = _names[next.name] ?? next.name;
    final remaining = _formatRemaining(next.timeUtc, state.nowUtc);

    return AppCard(
      onTap: onOpenSalat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.moonStar,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                next.isTomorrow
                    ? 'PROCHAINE PRIÈRE (DEMAIN)'
                    : 'PROCHAINE PRIÈRE',
                style: AppTypography.label.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(label, style: AppTypography.h1),
              const SizedBox(width: AppSpacing.s3),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$hh:$mm',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Dans $remaining',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  static String _formatRemaining(DateTime nextUtc, DateTime nowUtc) {
    final diff = nextUtc.difference(nowUtc);
    if (diff.isNegative) return 'maintenant';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours == 0) return '$minutes min';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PlaceholderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  subtitle,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenericError extends StatelessWidget {
  final String message;
  const _GenericError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Center(
        child: Text(
          'Une erreur est survenue.\n$message',
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
