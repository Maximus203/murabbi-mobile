import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/presentation/widgets/app_badge.dart';
import 'package:murabbi_mobile/presentation/widgets/app_bottom_nav.dart';
import 'package:murabbi_mobile/presentation/widgets/app_button.dart';
import 'package:murabbi_mobile/presentation/widgets/app_card.dart';
import 'package:murabbi_mobile/presentation/widgets/app_header.dart';
import 'package:murabbi_mobile/presentation/widgets/app_input.dart';
import 'package:murabbi_mobile/presentation/widgets/app_progress_ring.dart';
import 'package:murabbi_mobile/presentation/widgets/app_toggle.dart';

/// Goldens des 8 widgets atomiques Phase 1.
///
/// Stratégie : un golden par widget, sur fond `bgPrimary`. La police système
/// (Roboto / Helvetica selon le runner) est utilisée tant que les fichiers
/// Geist ne sont pas bundlés — `loadAppFonts()` dans `flutter_test_config.dart`
/// charge la police par défaut pour stabiliser le rendu cross-platform.
Widget _frame(Widget child, {double width = 360}) {
  return MaterialApp(
    theme: AppTheme.light(),
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  // ---------------------------- AppButton -----------------------------------
  testGoldens('AppButton — 5 variants', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(label: 'Continuer', onPressed: _noop),
            SizedBox(height: 8),
            AppButton(
              label: 'Modifier',
              onPressed: _noop,
              variant: AppButtonVariant.secondary,
            ),
            SizedBox(height: 8),
            AppButton(
              label: 'Continuer avec Google',
              onPressed: _noop,
              variant: AppButtonVariant.ghost,
            ),
            SizedBox(height: 8),
            AppButton(
              label: 'Supprimer',
              onPressed: _noop,
              variant: AppButtonVariant.destructive,
              leadingIcon: LucideIcons.trash2,
            ),
            SizedBox(height: 8),
            AppButton(
              label: 'Mot de passe oublié ?',
              onPressed: _noop,
              variant: AppButtonVariant.link,
            ),
            SizedBox(height: 8),
            AppButton(label: 'Disabled', onPressed: null),
          ],
        ),
      ),
      surfaceSize: const Size(400, 540),
    );
    await screenMatchesGolden(tester, 'app_button_variants');
  });

  // ---------------------------- AppBadge ------------------------------------
  testGoldens('AppBadge — system + chips', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppBadge(label: 'Système'),
            AppBadge(
              label: 'Aspirant · Niveau 2',
              leadingIcon: LucideIcons.star,
            ),
            AppBadge(
              label: 'Religion',
              variant: AppBadgeVariant.chip,
              dotColor: AppColors.categoryReligion,
            ),
            AppBadge(
              label: 'Sport · actif',
              variant: AppBadgeVariant.chipActive,
              dotColor: AppColors.categorySport,
            ),
          ],
        ),
      ),
      surfaceSize: const Size(400, 200),
    );
    await screenMatchesGolden(tester, 'app_badge_variants');
  });

  // ---------------------------- AppCard -------------------------------------
  testGoldens('AppCard — basic', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CARTE SIMPLE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.4,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Titre de carte',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '16px radius · 0.5px border · padding 20',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
      surfaceSize: const Size(400, 200),
    );
    await screenMatchesGolden(tester, 'app_card_basic');
  });

  // ---------------------------- AppInput ------------------------------------
  testGoldens('AppInput — text + icon + password', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(label: 'Email', placeholder: 'vous@exemple.com'),
            SizedBox(height: 12),
            AppInput(
              label: 'Avec icône',
              placeholder: 'vous@exemple.com',
              leadingIcon: LucideIcons.mail,
            ),
            SizedBox(height: 12),
            AppInput(
              label: 'Mot de passe',
              placeholder: '••••••••',
              leadingIcon: LucideIcons.lock,
              isPassword: true,
            ),
          ],
        ),
      ),
      surfaceSize: const Size(400, 320),
    );
    await screenMatchesGolden(tester, 'app_input_modes');
  });

  // ---------------------------- AppProgressRing ----------------------------
  testGoldens('AppProgressRing — 75% with center label', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(AppProgressRing(progress: 0.75, centerLabel: '75')),
      surfaceSize: const Size(220, 220),
    );
    await screenMatchesGolden(tester, 'app_progress_ring_75');
  });

  // ---------------------------- AppToggle -----------------------------------
  testGoldens('AppToggle — off + on', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppToggle(value: false, onChanged: _noopBool),
            SizedBox(width: 24),
            AppToggle(value: true, onChanged: _noopBool),
          ],
        ),
      ),
      surfaceSize: const Size(220, 80),
    );
    await screenMatchesGolden(tester, 'app_toggle_states');
  });

  // ---------------------------- AppHeader -----------------------------------
  testGoldens('AppHeader — title + back', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHeader.title(
              title: 'Mes habitudes',
              trailing: IconButton(
                onPressed: _noop,
                icon: Icon(LucideIcons.plus, size: 18, color: AppColors.accent),
              ),
            ),
            SizedBox(height: 8),
            AppHeader.back(title: 'Nouvelle habitude', onBack: _noop),
          ],
        ),
      ),
      surfaceSize: const Size(400, 180),
    );
    await screenMatchesGolden(tester, 'app_header_variants');
  });

  // ---------------------------- AppBottomNav --------------------------------
  testGoldens('AppBottomNav — home active', (tester) async {
    await tester.pumpWidgetBuilder(
      _frame(
        const AppBottomNav(
          active: AppBottomNavTab.home,
          onTabSelected: _noopTab,
        ),
        width: 400,
      ),
      surfaceSize: const Size(420, 100),
    );
    await screenMatchesGolden(tester, 'app_bottom_nav_home_active');
  });
}

void _noop() {}

void _noopBool(bool _) {}

void _noopTab(AppBottomNavTab _) {}
