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
          onStart: (_, _, _) {},
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
}
