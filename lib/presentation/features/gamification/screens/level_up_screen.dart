import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';

/// Écran de félicitations affiché lors d'un passage de niveau (Phase 5).
///
/// Fond vidéo décoratif plein écran (08.mp4). Le contenu (niveau obtenu,
/// CTA continuer) est superposé via un gradient sombre.
class LevelUpScreen extends StatelessWidget {
  /// Label du nouveau niveau (ex : "Aspirant", "Constant", …).
  final String levelName;

  /// Callback déclenchée par "Continuer" — le caller gère la navigation.
  final VoidCallback onContinue;

  const LevelUpScreen({
    super.key,
    required this.levelName,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vidéo de fond plein écran
          AppVideoBackground(
            assetPath: 'assets/media/08.mp4',
            overlay: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ),
          // Contenu superposé
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NIVEAU ATTEINT',
                    style: AppTypography.label.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    levelName,
                    style: AppTypography.display.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    'Félicitations ! Tu franchis un nouveau palier dans ta croissance.',
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  AppButton(label: 'Continuer', onPressed: onContinue),
                  const SizedBox(height: AppSpacing.s4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
