import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/app/first_tour.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

void main() {
  Future<void> openTour(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: questlyTheme(dark: false),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFirstTour(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('recorre los pasos con Siguiente y termina con ¡Vamos!', (
    tester,
  ) async {
    await openTour(tester);
    final total = firstTourSteps.length;
    for (var i = 0; i < total; i++) {
      expect(find.text(firstTourSteps[i].$2), findsOneWidget);
      expect(find.text('${i + 1} de $total'), findsOneWidget);
      await tester.tap(find.text(i == total - 1 ? '¡Vamos!' : 'Siguiente'));
      await tester.pumpAndSettle();
    }
    expect(find.text(firstTourSteps.last.$2), findsNothing);
  });

  testWidgets('tocar fuera la cierra sin seguir', (tester) async {
    await openTour(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text(firstTourSteps[0].$2), findsNothing);
    expect(find.text(firstTourSteps[1].$2), findsNothing);
  });
}
