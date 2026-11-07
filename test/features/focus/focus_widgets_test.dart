import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/focus_progress_widgets.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/focus_setup_view.dart';
import 'package:proyecto_movil/features/focus/presentation/widgets/focus_timer_ring.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SizedBox(width: 360, child: child)),
    ),
  );

  testWidgets('la ruta suma ciclos y descansos (largo cada 4) y da la hora '
      'de fin', (tester) async {
    // 5 ciclos de 25 + descansos 5, 5, 5, 15 = 155 min.
    await pump(
      tester,
      SessionRoute(
        board: const FocusBoard(),
        cycles: 5,
        cycleMinutes: 25,
        now: DateTime(2026, 11, 1, 16, 0),
      ),
    );

    expect(find.text('Terminas a las 18:35'), findsOneWidget);
    expect(
      find.text('5 ciclos de 25 min · 4 descansos · 2 h 35 min en total'),
      findsOneWidget,
    );
  });

  testWidgets('el cronómetro muestra el tiempo y su fase', (tester) async {
    await pump(
      tester,
      const FocusTimerRing(
        remaining: Duration(minutes: 12, seconds: 5),
        total: Duration(minutes: 25),
        label: 'Foco',
        footer: '',
        accent: Colors.red,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('12:05'), findsOneWidget);
    expect(find.text('Foco'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la tarjeta de la tarea muestra sus pasos y marca uno', (
    tester,
  ) async {
    String? done;
    await pump(
      tester,
      FocusTaskCard(
        task: const FocusTask(
          id: 't1',
          title: 'Informe',
          steps: [
            FocusStep(id: 'p1', title: 'Esquema', done: true),
            FocusStep(id: 'p2', title: 'Borrador'),
          ],
        ),
        heading: 'Ahora mismo',
        accent: Colors.red,
        busy: false,
        onCompleteStep: (id) => done = id,
        onAddStep: () {},
      ),
    );

    expect(find.text('1 de 2 pasos'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Hecho: «Borrador»'));
    expect(done, 'p2');
    expect(find.text('Añadir paso'), findsOneWidget);
  });

  testWidgets('el resumen cuenta qué terminaste, la semana y qué sigue, '
      'sin desbordar con texto grande', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SessionStoryCard(
                summary: const FocusSummary(
                  cycles: 2,
                  xp: 20,
                  coins: 6,
                  minutes: 50,
                  weekMinutes: 120,
                  prevWeekMinutes: 90,
                  tasks: [
                    FocusTask(id: 't1', title: 'Leer', done: true),
                    FocusTask(
                      id: 't2',
                      title: 'Informe',
                      steps: [FocusStep(id: 'p1', title: 'Esquema')],
                    ),
                  ],
                ),
                busy: false,
                scheduledAt: null,
                onSchedule: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 tarea terminada. ¡Bien hecho!'), findsOneWidget);
    expect(
      find.text('Esta semana llevas 2 h en foco, 30 min más que la anterior.'),
      findsOneWidget,
    );
    expect(find.text('Informe · Esquema'), findsOneWidget);
    expect(find.text('Agendar para mañana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
