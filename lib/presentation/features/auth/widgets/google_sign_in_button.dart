import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Bouton « Continuer avec Google » conforme aux Google Sign-In Branding
/// Guidelines (#119) :
/// - logo « G » multicolore à gauche,
/// - fond blanc, bordure `#DADCE0`,
/// - hauteur / radius alignés sur [kMinInteractiveDimension] et le DS Murabbi.
///
/// [onPressed] à `null` désactive le bouton (état chargement) — opacité 0.5
/// et `Semantics.enabled` false pour VoiceOver / TalkBack.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({super.key, required this.onPressed});

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.button);

    final button = Semantics(
      button: true,
      enabled: _enabled,
      label: 'Continuer avec Google',
      child: Material(
        color: AppColors.googleSurface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: AppColors.googleBorder,
            width: AppBorderWidth.thin,
          ),
          borderRadius: radius,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            height: kMinInteractiveDimension,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GoogleGlyph(size: 18),
                const SizedBox(width: AppSpacing.s3),
                Text(
                  'Continuer avec Google',
                  style: AppTypography.body.copyWith(
                    color: AppColors.googleText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return _enabled ? button : Opacity(opacity: 0.5, child: button);
  }
}

/// Logo « G » Google multicolore dessiné en [CustomPaint] — évite d'embarquer
/// un asset binaire. Les quatre arcs reprennent les couleurs officielles
/// (cf. [AppColors] § marques tierces).
class _GoogleGlyph extends StatelessWidget {
  final double size;
  const _GoogleGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final stroke = w * 0.22;

    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Quatre arcs colorés du « G ».
    canvas.drawArc(rect, -0.35, -1.22, false, arcPaint(AppColors.googleRed));
    canvas.drawArc(rect, -1.57, -1.40, false, arcPaint(AppColors.googleYellow));
    canvas.drawArc(rect, 1.30, 1.40, false, arcPaint(AppColors.googleGreen));
    canvas.drawArc(rect, 0.55, 0.75, false, arcPaint(AppColors.googleBlue));

    // Barre horizontale bleue du « G ».
    final barPaint = Paint()..color = AppColors.googleBlue;
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        w,
        center.dy + stroke / 2,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
