import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_duration.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Anneau de progression — utilisé sur HM-01 (score quotidien) et HB-EXECUTE
/// (timer count-down) en Phase 4. Logique pure, paint sobre, ZÉRO ombre.
class AppProgressRing extends StatelessWidget {
  /// Progression [0..1] — clampé à la construction.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  /// Texte central (ex: "12:34" pour le timer, "75" pour le score).
  final String? centerLabel;

  AppProgressRing({
    super.key,
    required double progress,
    this.size = 120,
    this.strokeWidth = 6,
    this.trackColor = AppColors.borderDefault,
    this.progressColor = AppColors.accent,
    this.centerLabel,
  }) : progress = progress.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          strokeWidth: strokeWidth,
          trackColor: trackColor,
          progressColor: progressColor,
        ),
        child: centerLabel == null
            ? null
            : Center(
                child: Text(
                  centerLabel!,
                  style: AppTypography.display.copyWith(fontSize: size / 3.5),
                ),
              ),
      ),
    );
  }
}

/// Variante animée de [AppProgressRing].
///
/// Tweens [from] → [progress] sur [duration] à chaque rebuild où `progress`
/// change. Utilisée sur HM-01 (score quotidien) et HB-EXECUTE (timer countdown).
class AnimatedProgressRing extends StatelessWidget {
  final double progress;
  final double from;
  final Duration duration;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final String? centerLabel;

  AnimatedProgressRing({
    super.key,
    required double progress,
    double from = 0.0,
    this.duration = AppDuration.slow,
    this.size = 120,
    this.strokeWidth = 6,
    this.trackColor = AppColors.borderDefault,
    this.progressColor = AppColors.accent,
    this.centerLabel,
  }) : progress = progress.clamp(0.0, 1.0),
       from = from.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from, end: progress),
      duration: duration,
      curve: Curves.easeOut,
      builder: (_, value, _) => AppProgressRing(
        progress: value,
        size: size,
        strokeWidth: strokeWidth,
        trackColor: trackColor,
        progressColor: progressColor,
        centerLabel: centerLabel,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final fg = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      const start = -math.pi / 2;
      final sweep = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
