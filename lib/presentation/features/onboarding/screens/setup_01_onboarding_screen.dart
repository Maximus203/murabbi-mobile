import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/features/onboarding/providers/onboarding_notifier.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_media.dart';
import 'package:murabbi_mobile/presentation/theme/app_spacing.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_video_background.dart';

/// Modèle léger d'un slide d'onboarding. Volontairement statelessful — la
/// configuration réelle (lieu, méthode de calcul, DST) est pilotée plus tard
/// via `services/prayer_settings`.
class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;

  /// Chemin asset vidéo décoratif optionnel (ex. 'assets/media/03.mp4').
  /// Lorsque non null, un bandeau [AppVideoBackground] est affiché au-dessus
  /// du cercle d'icône.
  final String? videoAsset;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
    this.videoAsset,
  });
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    icon: LucideIcons.mapPin,
    title: 'Localisation',
    body:
        'Murabbi détecte ta ville pour calculer les horaires de prière au plus juste. Tu pourras affiner manuellement dans Réglages.',
    // OB-04 → 03_murabbi — ADR-017 : vidéo bundlée assets/videos/
    videoAsset: AppMedia.onboarding04Video,
  ),
  _OnboardingSlide(
    icon: LucideIcons.calculator,
    title: 'Méthode de calcul',
    body:
        'Choisis la méthode (MWL, ISNA, UmmAlQura, …) qui correspond à ton école. La valeur par défaut convient à 80 % des utilisateurs.',
    // OB-03 → 04_murabbi — ADR-017 : vidéo bundlée assets/videos/
    videoAsset: AppMedia.onboarding03Video,
  ),
  _OnboardingSlide(
    icon: LucideIcons.clock,
    title: 'Heure d\'été automatique',
    body:
        'Les horaires s\'ajustent automatiquement avec le passage à l\'heure d\'été / d\'hiver, selon ton fuseau (Africa/Dakar par défaut).',
    // OB-02 → 06_murabbi — ADR-017 : vidéo bundlée assets/videos/
    videoAsset: AppMedia.onboarding02Video,
  ),
  _OnboardingSlide(
    icon: LucideIcons.circleCheck,
    title: 'Tout est prêt',
    body:
        'Tu peux commencer à valider tes prières et tes habitudes dès maintenant. Bonne route, ya Murabbi.',
  ),
];

/// SETUP-01 — Configuration prière (4 slides walkthrough).
///
/// MVP slice D : informationnel, pas de saisie de settings réelle (la table
/// `users.prayer_method` / `prayer_location` arrivera quand Q-18 mobile sera
/// finalisée). Skip ou "Commencer" marquent l'onboarding complété.
class Setup01OnboardingScreen extends ConsumerStatefulWidget {
  /// Callback déclenché quand l'utilisateur termine ou passe (le routeur
  /// redirigera ensuite vers /home en réponse à la mise à jour du flag).
  final VoidCallback onCompleted;

  const Setup01OnboardingScreen({super.key, required this.onCompleted});

  @override
  ConsumerState<Setup01OnboardingScreen> createState() =>
      _Setup01OnboardingScreenState();
}

class _Setup01OnboardingScreenState
    extends ConsumerState<Setup01OnboardingScreen> {
  final _pageCtrl = PageController();
  int _index = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  Future<void> _next() async {
    if (_isLast) {
      await _complete();
      return;
    }
    await _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _complete() async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref.read(onboardingNotifierProvider.notifier).markCompleted();
    if (!mounted) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onSkip: _saving ? null : _complete),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _DotsIndicator(count: _slides.length, index: _index),
            const SizedBox(height: AppSpacing.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
              child: Row(
                children: [
                  if (_index > 0) ...[
                    Expanded(
                      child: AppButton(
                        label: 'Précédent',
                        variant: AppButtonVariant.ghost,
                        onPressed: _saving
                            ? null
                            : () => _pageCtrl.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                  ],
                  Expanded(
                    child: AppButton(
                      label: _saving
                          ? 'Enregistrement…'
                          : (_isLast ? 'Commencer' : 'Suivant'),
                      onPressed: _saving ? null : _next,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onSkip;
  const _TopBar({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Passer',
              style: AppTypography.body.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s5,
        vertical: AppSpacing.s4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (slide.videoAsset != null) ...[
            AppVideoBackground(
              assetPath: slide.videoAsset!,
              height: 160,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            const SizedBox(height: AppSpacing.s4),
          ],
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.25),
                width: AppBorderWidth.thin,
              ),
            ),
            child: Icon(slide.icon, size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: AppSpacing.s5),
          Text(
            slide.title,
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            slide.body,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : AppColors.borderDefault,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
