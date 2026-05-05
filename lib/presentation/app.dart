import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';
import 'package:murabbi_mobile/presentation/theme/app_typography.dart';

/// Routeur Murabbi — shell vide en Phase 1.
/// Les routes réelles (auth, onboarding, dashboard, …) arrivent en Phase 2+.
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const _PlaceholderScreen()),
  ],
);

/// Racine de l'application Murabbi.
class MurabbiApp extends ConsumerWidget {
  const MurabbiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Murabbi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}

/// Écran placeholder Phase 1 — vérifie que les tokens DS s'appliquent au
/// runtime. Sera remplacé par le splash + auth en Phase 2.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Murabbi', style: AppTypography.h1),
              SizedBox(height: 4),
              Text(
                'Phase 1 — Design system bootstrapped',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
