import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/domain/entities/habit.dart';
import 'package:murabbi_mobile/domain/entities/habit_target.dart';
import 'package:murabbi_mobile/domain/value_objects/target_unit.dart';
import 'package:murabbi_mobile/presentation/features/habits/providers/habit_timer_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_responsive.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';

/// Modal plein écran du timer in-app — variantes A.1 → A.3 (spec v1.5 § 3.5).
///
/// A.1 : timer au repos (play + "Valider sans timer")
/// A.2 : timer en cours (pause + stop)
/// A.3 : timer en pause (play + stop)
///
/// Appelée via [showHabitTimerSheet].
class HabitTimerSheet extends ConsumerWidget {
  final Habit habit;
  final HabitTargetTimed target;

  /// Appelé quand l'utilisateur valide (avec ou sans avoir lancé le timer).
  /// [elapsed] = durée effectivement mesurée (peut être zéro).
  final void Function(Duration elapsed) onValidate;

  const HabitTimerSheet({
    super.key,
    required this.habit,
    required this.target,
    required this.onValidate,
  });

  Duration get _targetDuration {
    final v = target.value.value;
    return target.unit == TargetUnit.hours
        ? Duration(hours: v)
        : Duration(minutes: v);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(habitTimerProvider(_targetDuration));
    final notifier = ref.read(habitTimerProvider(_targetDuration).notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name.value, style: AppTypography.h1),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        _subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    icon: Icon(LucideIcons.x, size: context.rs(AppIconSize.nav)),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),

              // ── Statut textuel ────────────────────────────────────────
              Text(
                _statusLine(timerState),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const Spacer(),

              // ── Cercle de progression ─────────────────────────────────
              Center(child: _TimerCircle(state: timerState)),
              const Spacer(),

              // ── Boutons play / pause / stop ───────────────────────────
              Center(
                child: _ControlButtons(
                  state: timerState,
                  onPlay: notifier.play,
                  onPause: notifier.pause,
                  onStop: () {
                    notifier.stop();
                    Navigator.of(context).pop();
                    onValidate(timerState.elapsed);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s4),

              // ── Hint contextuel ───────────────────────────────────────
              Center(
                child: Text(
                  _hint(timerState),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.s5),

              // ── Bouton principal ──────────────────────────────────────
              _PrimaryButton(
                state: timerState,
                onValidateWithoutTimer: () {
                  notifier.stop();
                  Navigator.of(context).pop();
                  onValidate(Duration.zero);
                },
                onStopAndValidate: () {
                  notifier.stop();
                  Navigator.of(context).pop();
                  onValidate(timerState.elapsed);
                },
              ),

              // ── Lien valider sans timer (A.1 uniquement) ─────────────
              if (timerState.status == HabitTimerStatus.initial) ...[
                const SizedBox(height: AppSpacing.s3),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onValidate(Duration.zero);
                    },
                    child: Text(
                      'Vous pouvez aussi valider sans démarrer le timer',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final v = target.value.value;
    final unit = target.unit == TargetUnit.hours ? 'h' : 'min';
    return '$v $unit · timer';
  }

  String _statusLine(HabitTimerState s) {
    switch (s.status) {
      case HabitTimerStatus.initial:
        final v = target.value.value;
        final u = target.unit == TargetUnit.hours ? 'h' : 'min';
        return '$v $u · timer · prêt';
      case HabitTimerStatus.running:
        return 'En cours · ${_fmt(s.elapsed)} écoulées';
      case HabitTimerStatus.paused:
        return 'En pause · ${_fmt(s.elapsed)} écoulées';
      case HabitTimerStatus.completed:
        return 'Terminé · ${_fmt(s.elapsed)} écoulées';
    }
  }

  String _hint(HabitTimerState s) {
    switch (s.status) {
      case HabitTimerStatus.initial:
        return 'Préparez votre espace, puis démarrez quand vous êtes prêt';
      case HabitTimerStatus.running:
        return 'Une notification vous préviendra à 5 minutes de la fin';
      case HabitTimerStatus.paused:
        return 'Reprenez quand vous êtes prêt — le compte continuera là où il s\'est arrêté';
      case HabitTimerStatus.completed:
        return 'Bravo ! Timer terminé.';
    }
  }
}

/// Ouvre le modal timer en plein écran.
Future<void> showHabitTimerSheet(
  BuildContext context, {
  required Habit habit,
  required HabitTargetTimed target,
  required void Function(Duration elapsed) onValidate,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black26,
      pageBuilder: (context, animation, secondaryAnimation) => ProviderScope(
        child: HabitTimerSheet(
          habit: habit,
          target: target,
          onValidate: onValidate,
        ),
      ),
    ),
  );
}

// ── Cercle de progression ─────────────────────────────────────────────────────

class _TimerCircle extends StatelessWidget {
  final HabitTimerState state;
  const _TimerCircle({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _CircleProgressPainter(progress: state.progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmt(state.remaining),
                style: AppTypography.displayXl.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              if (state.status == HabitTimerStatus.paused)
                Text(
                  'en pause',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                )
              else
                Text(
                  'min · sec',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final trackPaint = Paint()
      ..color = AppColors.bgInput
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final progressPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.progress != progress;
}

// ── Boutons de contrôle ───────────────────────────────────────────────────────

class _ControlButtons extends StatelessWidget {
  final HabitTimerState state;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const _ControlButtons({
    required this.state,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      HabitTimerStatus.initial => _RoundButton(
        icon: Icons.play_arrow_rounded,
        onTap: onPlay,
        filled: true,
      ),
      HabitTimerStatus.running => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundButton(icon: Icons.pause_rounded, onTap: onPause),
          const SizedBox(width: AppSpacing.s4),
          _RoundButton(icon: Icons.stop_rounded, onTap: onStop),
        ],
      ),
      HabitTimerStatus.paused => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundButton(
            icon: Icons.play_arrow_rounded,
            onTap: onPlay,
            filled: true,
          ),
          const SizedBox(width: AppSpacing.s4),
          _RoundButton(icon: Icons.stop_rounded, onTap: onStop),
        ],
      ),
      HabitTimerStatus.completed => _RoundButton(
        icon: Icons.check_rounded,
        onTap: onStop,
        filled: true,
      ),
    };
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : AppColors.bgInput,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 30,
          color: filled ? AppColors.bgSurface : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Bouton principal ──────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final HabitTimerState state;
  final VoidCallback onValidateWithoutTimer;
  final VoidCallback onStopAndValidate;

  const _PrimaryButton({
    required this.state,
    required this.onValidateWithoutTimer,
    required this.onStopAndValidate,
  });

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      HabitTimerStatus.initial => AppButton(
        label: '✓ Valider l\'habitude',
        onPressed: onValidateWithoutTimer,
      ),
      HabitTimerStatus.running || HabitTimerStatus.paused => AppButton(
        label: 'Arrêter le timer pour valider',
        onPressed: onStopAndValidate,
      ),
      HabitTimerStatus.completed => AppButton(
        label: '✓ Valider l\'habitude',
        onPressed: onStopAndValidate,
      ),
    };
  }
}

// ── Utilitaire ────────────────────────────────────────────────────────────────

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
