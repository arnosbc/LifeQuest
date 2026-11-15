import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/habits/data/repositories/habits_repository_impl.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit_plan.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/habit_plan_usecases.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_plan_sheet.dart';

import '../../../helpers/mocks.dart';
import '../habits_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('HabitsRepositoryImpl · plan de Nevi (065)', () {
    late MockHabitsRemoteDataSource remote;
    late HabitsRepositoryImpl repository;

    setUp(() {
      remote = MockHabitsRemoteDataSource();
      repository = HabitsRepositoryImpl(remote);
    });

    test('lee el plan guardado; sin versión mínima no hay plan', () async {
      when(() => remote.getPlan('h1')).thenAnswer(
        (_) async => {
          'tiny': ' Leer una página ',
          'cue': 'Después de cenar',
          'why': '',
        },
      );
      expect(
        await repository.getPlan('h1'),
        const Right<dynamic, HabitPlan?>(
          HabitPlan(tiny: 'Leer una página', cue: 'Después de cenar'),
        ),
      );
      when(() => remote.getPlan('h2')).thenAnswer((_) async => {'cue': 'x'});
      expect((await repository.getPlan('h2')).toNullable(), isNull);
    });

    test('si la IA no responde, avisa en tono amable', () async {
      when(
        () => remote.generatePlan('h1'),
      ).thenThrow(const ServerException(code: 'plan_unavailable'));
      final result = await repository.generatePlan('h1');
      expect(
        result.getLeft().toNullable()?.message,
        contains('Nevi no pudo armar tu plan'),
      );
    });
  });

  testWidgets('la hoja pide el plan a Nevi y lo muestra (360 dp, 1,3×)', (
    tester,
  ) async {
    final repo = MockHabitsRepository();
    when(() => repo.getPlan(any())).thenAnswer((_) async => const Right(null));
    when(() => repo.generatePlan(any())).thenAnswer(
      (_) async => const Right(
        HabitPlan(
          tiny: 'Leer una página',
          cue: 'Después de cenar, abro el libro',
          reward: 'Marco el día',
          why: 'Leer te calma',
        ),
      ),
    );
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final habit = goodHabit;
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
              onPressed: () => showHabitPlanSheet(
                context,
                habit: habit,
                getPlan: GetHabitPlan(repo),
                generatePlan: GenerateHabitPlan(repo),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Que Nevi arme mi plan'), findsOneWidget);
    await tester.tap(find.text('Que Nevi arme mi plan'));
    await tester.pumpAndSettle();
    expect(find.text('Leer una página'), findsOneWidget);
    expect(find.text('Después de cenar, abro el libro'), findsOneWidget);
    expect(find.text('Rehacer el plan'), findsOneWidget);
    expect(habit.type, HabitType.good);
    expect(tester.takeException(), isNull);
  });
}
