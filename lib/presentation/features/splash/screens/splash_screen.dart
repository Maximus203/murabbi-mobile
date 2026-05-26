import 'package:flutter/material.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';

/// Splash OB-01 — fond vidéo fullscreen + logo blanc centré + spinner.
///
/// Affiché tant que `authNotifierProvider` ou `onboardingNotifierProvider`
/// est en `loading()`. Le routeur redirigera dès que les deux sont résolus.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: AppVideoBackground(
        assetPath: 'assets/media/02.mp4',
        overlay: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Murabbi',
                style: AppTypography.h1.copyWith(color: AppColors.bgSurface),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Bismi-Llāh',
                style: AppTypography.caption.copyWith(
                  color: AppColors.bgSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              const SizedBox(
                width: AppSpacing.s6,
                height: AppSpacing.s6,
                child: CircularProgressIndicator(
                  strokeWidth: AppBorderWidth.indicatorStroke,
                  color: AppColors.bgSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
            ],
          ),
        ),
      ),
    );
  }
}
