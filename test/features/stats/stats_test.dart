import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/stats/data/models/stats_board_model.dart';
import 'package:proyecto_movil/features/stats/domain/entities/stats_board.dart';
import 'package:proyecto_movil/features/stats/presentation/blocs/stats_bloc.dart';

import '../../helpers/mocks.dart';

void main() {
  test('StatsBoardModel convierte stats_overview', () {
    final b = StatsBoardModel.fromJson({
      'xp': 120,
      'xp_prev': 80,
      'focus_minutes': 50,
      'xp_by_day': [
        {'day': '2026-10-26', 'xp': 20},
        {'day': '2026-10-27', 'xp': 100},
      ],
      'xp_by_skill': [
        {'name': 'Salud', 'xp': 60},
      ],
      'top_habits': [
        {'name': 'Leer', 'days': 12, 'streak': 4},
      ],
    }).toEntity();
    expect([b.xp, b.focusMinutes, b.xpByDay.last.xp], [120, 50, 100]);
    expect(
      b.topHabits.single,
      const HabitConsistency(name: 'Leer', days: 12, streak: 4),
    );
  });

  group('observaciones de RPGenie', () {
    test('comparan con la semana anterior, el mejor día y el Área', () {
      final b = StatsBoard(
        xp: 120,
        xpPrev: 80,
        xpByDay: [
          DayXp(DateTime(2026, 10, 26), 20),
          DayXp(DateTime(2026, 10, 27), 100),
        ],
        xpBySkill: const [SkillXp('Salud', 60)],
      );
      expect(b.observations, [
        'Ganaste 40 XP más que la semana pasada. ¡Vas en subida!',
        'Tu mejor día fue el martes: 100 XP.',
        'Salud es el Área que más creció esta semana.',
      ]);
    });

    test('sin actividad invitan sin culpa y siempre son 3 o menos', () {
      final notes = const StatsBoard().observations;
      expect(notes.first, contains('una misión pequeña basta'));
      expect(notes.length, lessThanOrEqualTo(3));
      for (final n in notes) {
        expect(n.toLowerCase(), isNot(contains('perder')));
      }
    });
  });

  final now = DateTime(2026, 10, 27, 9);
  blocTest<StatsBloc, StatsState>(
    'la primera carga pasa por Loading y termina en Success',
    build: () {
      final getStats = MockGetStats();
      when(
        () => getStats(now),
      ).thenAnswer((_) async => const Right(StatsBoard()));
      return StatsBloc(getStats: getStats, clock: () => now);
    },
    act: (bloc) => bloc.add(const StatsRequested()),
    expect: () => [const StatsLoading(), const StatsSuccess(StatsBoard())],
  );
}
