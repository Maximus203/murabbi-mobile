import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/entities/prayer_status.dart';
import 'package:murabbi_mobile/presentation/features/salat/widgets/status_picker_bottom_sheet.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    required PrayerStatus current,
  }) async {
    late BuildContext capturedCtx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              capturedCtx = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    StatusPickerBottomSheet.show(
      capturedCtx,
      prayerLabel: 'Fajr',
      current: current,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('affiche le label de la prière + les 5 statuts', (tester) async {
    await openSheet(tester, current: PrayerStatus.pending);

    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text("À l'heure"), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('Manquée'), findsOneWidget);
    expect(find.text('Rattrapée'), findsOneWidget);
    expect(find.text('Non priée'), findsOneWidget);
  });

  testWidgets('Navigator.pop renvoie le statut tapé', (tester) async {
    late BuildContext capturedCtx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              capturedCtx = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    final future = StatusPickerBottomSheet.show(
      capturedCtx,
      prayerLabel: 'Dhuhr',
      current: PrayerStatus.pending,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text("À l'heure"));
    await tester.pumpAndSettle();

    expect(await future, PrayerStatus.onTime);
  });
}
