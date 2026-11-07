import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/presentation/blocs/tasks_bloc.dart';
import 'package:proyecto_movil/features/tasks/presentation/screens/tasks_screen.dart';

import '../../../../helpers/mocks.dart';
import '../../tasks_fixtures.dart';

void main() {
  late MockTasksBloc bloc;
  String? focusTask;

  setUp(() {
    bloc = MockTasksBloc();
    focusTask = null;
  });

  Future<void> pump(WidgetTester tester, TasksBoard board) async {
    whenListen(
      bloc,
      const Stream<TasksState>.empty(),
      initialState: TasksSuccess(board),
    );
    tester.view.physicalSize = const Size(393, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<TasksBloc>.value(
            value: bloc,
            child: TasksScreen(
              onStartFocus: ([id]) => focusTask = id,
              onOpenProjects: () {},
              onCreate: () async => false,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('agrupa en Hoy (con lo vencido), Próximas y Sin fecha', (
    tester,
  ) async {
    final now = DateTime.now();
    Task due(String id, DateTime? date) => Task(
      id: id,
      title: id,
      priority: TaskPriority.medium,
      bucket: TaskBucket.medium,
      xpReward: 10,
      coinReward: 3,
      dueDate: date,
    );
    await pump(
      tester,
      TasksBoard(
        tasks: [
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
    await tester.tap(find.text('Empezar foco'));
    expect(focusTask, 'vencida'); // la primera abre Foco con su id
  });

  testWidgets('sin tareas muestra la ilustración y la invitación', (
    tester,
  ) async {
    await pump(tester, emptyBoard);

    expect(find.text('No tienes tareas abiertas'), findsOneWidget);
    expect(find.text('Nueva tarea'), findsOneWidget);
  });
}
