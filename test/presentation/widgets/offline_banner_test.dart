import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:murabbi_mobile/presentation/theme/app_colors.dart';
import 'package:murabbi_mobile/presentation/widgets/offline_banner.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('OfflineBanner', () {
    testWidgets('affiche un message + icône wifiOff', (tester) async {
      await tester.pumpWidget(_wrap(const OfflineBanner()));
      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);
      expect(find.text('Hors ligne'), findsOneWidget);
    });

    testWidgets('fond AppColors.warning', (tester) async {
      await tester.pumpWidget(_wrap(const OfflineBanner()));
      final container = tester.widget<Container>(
        find.byKey(const Key('offline-banner-container')),
      );
      expect(
        (container.decoration as BoxDecoration?)?.color ?? container.color,
        AppColors.warning,
      );
    });

    testWidgets('hauteur fixe 32px', (tester) async {
      await tester.pumpWidget(_wrap(const OfflineBanner()));
      final size = tester.getSize(
        find.byKey(const Key('offline-banner-container')),
      );
      expect(size.height, 32);
    });
  });
}
