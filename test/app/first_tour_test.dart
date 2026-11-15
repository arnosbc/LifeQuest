import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/app/first_tour.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showFirstTour(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('Nevi muestra 3 pasos y cabe en 360 dp con 1,3×', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Hola, soy Nevi 👋 · Tu camino de hoy'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('La barra de arriba'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('El botón de ideas'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('¡Vamos!'));
    await tester.pumpAndSettle();
    expect(find.text('El botón de ideas'), findsNothing);
  });

  testWidgets('tocar fuera cierra la guía sin seguir', (tester) async {
    await open(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('La barra de arriba'), findsNothing);
  });
}
