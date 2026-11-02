import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/dungeon_setup_view.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/dungeon_timer_ring.dart';

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
        board: const DungeonBoard(),
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
      const DungeonTimerRing(
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
}
