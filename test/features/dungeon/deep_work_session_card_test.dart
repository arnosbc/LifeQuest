import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/deep_work_session_card.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const session = DungeonSession(
    id: 's1',
    totalMinutes: 60,
    cycleMinutes: 25,
    tasks: [
      DungeonTask(
        id: 't1',
        title: 'Ordenar mi escritorio',
        stepCount: 4,
        step: DungeonStep(
          id: 'p2',
          title: 'Separa lo que no usas',
          position: 2,
          minutes: 5,
        ),
      ),
    ],
    habits: [DungeonTask(id: 'h1', title: 'Leer', isHabit: true)],
  );

  Future<List<String>> pump(WidgetTester tester, String current) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeepWorkSessionCard(
              session: session,
              currentTaskId: current,
              busy: false,
              onSelect: (id) => calls.add('select $id'),
              onComplete: (id) => calls.add('complete $id'),
              onStepDone: (id) => calls.add('step $id'),
              onHabitDone: (id) => calls.add('habit $id'),
              onOpenSteps: (id) => calls.add('open $id'),
            ),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('AHORA muestra el paso que toca y lo marca sin salir', (
    tester,
  ) async {
    final calls = await pump(tester, 't1');
    expect(find.text('Paso 2 de 4 · ~5 min'), findsOneWidget);
    expect(find.text('Separa lo que no usas'), findsOneWidget);
    await tester.tap(find.text('Listo, siguiente paso'));
    await tester.tap(find.text('Revisar con fotos'));
    // El hábito queda abajo, para cambiar de foco.
    await tester.tap(find.text('Leer'));
    expect(calls, ['step p2', 'open t1', 'select h1']);
  });

  testWidgets('con un hábito en foco ofrece marcarlo como hecho', (
    tester,
  ) async {
    final calls = await pump(tester, 'h1');
    expect(find.text('Hábito de hoy'), findsWidgets);
    await tester.tap(find.text('Marcar hábito como hecho'));
    expect(calls, ['habit h1']);
  });
}
