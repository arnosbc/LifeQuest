import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/missions/presentation/screens/missions_screen.dart';

import '../../../../helpers/mocks.dart';
import '../../missions_fixtures.dart';

void main() {
  late MockMissionsBloc bloc;

  setUp(() => bloc = MockMissionsBloc());

  Future<void> pump(WidgetTester tester, MissionsBoard board) async {
    whenListen(
      bloc,
      const Stream<MissionsState>.empty(),
      initialState: MissionsSuccess(board),
    );
    tester.view.physicalSize = const Size(393, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<MissionsBloc>.value(
            value: bloc,
            child: MissionsScreen(onStartFocus: () {}, onOpenProjects: () {}),
          ),
        ),
      ),
    );
  }

  testWidgets('agrupa en Hoy (con lo vencido), Próximas y Sin fecha', (
    tester,
  ) async {
    final now = DateTime.now();
    Mission due(String id, DateTime? date) => Mission(
      id: id,
      title: id,
      priority: MissionPriority.medium,
      bucket: MissionBucket.medium,
      xpReward: 10,
      coinReward: 3,
      dueDate: date,
    );
    await pump(
      tester,
      MissionsBoard(
        missions: [
          due('vencida', now.subtract(const Duration(days: 2))),
          due('hoy', DateTime(now.year, now.month, now.day, 23, 59)),
          due('mañana', now.add(const Duration(days: 1))),
          due('sin fecha', null),
        ],
      ),
    );

    expect(find.text('Hoy · 2'), findsOneWidget);
    expect(find.text('Próximas · 1'), findsOneWidget);
    expect(find.text('Sin fecha · 1'), findsOneWidget);
    expect(find.text('40'), findsOneWidget); // XP en juego
    expect(find.text('Empezar foco'), findsOneWidget);
  });

  testWidgets('sin tareas muestra la ilustración y la invitación', (
    tester,
  ) async {
    await pump(tester, emptyBoard);

    expect(find.text('No tienes tareas abiertas'), findsOneWidget);
    expect(find.text('Nueva tarea'), findsOneWidget);
  });
}
