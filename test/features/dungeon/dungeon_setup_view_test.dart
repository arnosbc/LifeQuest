import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/dungeon_setup_view.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget view(DungeonBoard board) => MaterialApp(
    theme: LifeQuestTheme.dark,
    home: Scaffold(
      body: SingleChildScrollView(
        child: DungeonSetupView(
          board: board,
          busy: false,
          initialTaskId: 'nueva',
          onStart: (_, _, _, _) {},
        ),
      ),
    ),
  );

  testWidgets(
    'la tarea de «Empezar en Foco» queda marcada aunque llegue en la recarga',
    (tester) async {
      // Foco abre con el tablero viejo: la tarea recién creada aún no está.
      await tester.pumpWidget(
        view(
          const DungeonBoard(
            candidates: [DungeonTask(id: 'vieja', title: 'Otra tarea')],
          ),
        ),
      );
      expect(find.text('0 / 5'), findsOneWidget);
      // Llega el tablero recargado con la tarea nueva.
      await tester.pumpWidget(
        view(
          const DungeonBoard(
            candidates: [
              DungeonTask(id: 'vieja', title: 'Otra tarea'),
              DungeonTask(id: 'nueva', title: 'Ordenar el escritorio'),
            ],
          ),
        ),
      );
      expect(find.text('1 / 5'), findsOneWidget);
    },
  );

  test('el tiempo sugerido suma lo estimado y redondea a 30 min', () {
    const estimated = DungeonTask(id: 'a', title: 'A', minutes: 50);
    const plain = DungeonTask(id: 'b', title: 'B');
    const habit = DungeonTask(id: 'h', title: 'Leer', isHabit: true);
    // 50 + un bloque de 25 + 25 = 100 → 2 h.
    expect(DungeonSetupView.suggestedMinutes([estimated, plain, habit], 25), 120);
    // Nada estimado: al menos un ciclo, redondeado a 30.
    expect(DungeonSetupView.suggestedMinutes(const [], 45), 60);
    // Tope del servidor: 8 h.
    expect(
      DungeonSetupView.suggestedMinutes(
        const [DungeonTask(id: 'x', title: 'X', minutes: 900)],
        25,
      ),
      480,
    );
  });

  testWidgets('muestra los hábitos de hoy con su propia sección', (tester) async {
    await tester.pumpWidget(
      view(
        const DungeonBoard(
          candidates: [
            DungeonTask(id: 't', title: 'Ordenar', minutes: 25, stepCount: 4),
          ],
          habitCandidates: [DungeonTask(id: 'h', title: 'Leer', isHabit: true)],
        ),
      ),
    );
    expect(find.text('HÁBITOS DE HOY'), findsOneWidget);
    expect(find.text('Leer'), findsOneWidget);
    expect(find.text('4 pasos · ~25 min'), findsOneWidget);
  });
}
