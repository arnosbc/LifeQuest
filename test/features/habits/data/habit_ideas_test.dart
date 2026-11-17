import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/habits/data/repositories/habits_repository_impl.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit_idea.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/habit_plan_usecases.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_ideas_sheet.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'el repositorio limpia las ideas y avisa en tono amable si fallan',
    () async {
      final remote = MockHabitsRemoteDataSource();
      final repository = HabitsRepositoryImpl(remote);
      when(() => remote.suggestHabits()).thenAnswer(
        (_) async => [
          {
            'name': ' Caminar 10 minutos ',
            'why': 'Te despeja',
            'time': '07:30',
          },
          {'name': '  ', 'why': 'vacía', 'time': '08:00'},
          {'name': 'Estirar', 'why': null, 'time': null},
        ],
      );
      expect((await repository.suggestHabits()).toNullable(), const [
        HabitIdea(name: 'Caminar 10 minutos', why: 'Te despeja', time: '07:30'),
        HabitIdea(name: 'Estirar', why: ''),
      ]);
      when(
        () => remote.suggestHabits(),
      ).thenThrow(const ServerException(code: 'ideas_unavailable'));
      expect(
        (await repository.suggestHabits()).getLeft().toNullable()?.message,
        contains('Nevi no pudo pensar ideas'),
      );
    },
  );

  testWidgets('la hoja muestra 3 ideas y devuelve la elegida con su hora', (
    tester,
  ) async {
    final repo = MockHabitsRepository();
    when(() => repo.suggestHabits()).thenAnswer(
      (_) async => const Right([
        HabitIdea(name: 'Leer 2 páginas', why: 'Te calma', time: '21:00'),
        HabitIdea(name: 'Caminar 10 minutos', why: 'Te despeja', time: '07:30'),
        HabitIdea(name: 'Tomar agua', why: 'Te hidrata'),
      ]),
    );
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    NewHabit? chosen;
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => chosen = await showHabitIdeasSheet(
                context,
                SuggestHabits(repo),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Ideas de Nevi'), findsOneWidget);
    expect(find.text('Crear este hábito'), findsNWidgets(3));
    await tester.tap(find.text('Crear este hábito').first);
    await tester.pumpAndSettle();
    expect(
      chosen,
      const NewHabit(
        name: 'Leer 2 páginas',
        type: HabitType.good,
        reminderTime: '21:00',
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
