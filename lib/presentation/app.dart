import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murabbi_mobile/presentation/router/app_router.dart';
import 'package:murabbi_mobile/presentation/theme/app_theme.dart';

/// Racine de l'application Murabbi — branche le GoRouter Riverpod.
class MurabbiApp extends ConsumerWidget {
  const MurabbiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Murabbi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
