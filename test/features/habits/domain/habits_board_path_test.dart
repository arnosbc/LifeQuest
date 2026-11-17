import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';

Habit _h(
  String id,
  HabitPriority p, {
  bool done = false,
  bool today = true,
  HabitType type = HabitType.good,
}) => Habit(
  id: id,
  name: id,
  type: type,
  priority: p,
  doneToday: done,
  scheduledToday: today,
);

void main() {
  test('el Camino ordena por prioridad, estable y solo con lo de hoy', () {
    final board = HabitsBoard(
      habits: [
        _h('baja', HabitPriority.low),
        _h('media1', HabitPriority.medium),
        _h('alta', HabitPriority.high),
        _h('media2', HabitPriority.medium),
        _h('manana', HabitPriority.high, today: false),
        _h('malo', HabitPriority.high, type: HabitType.bad),
      ],
    );
    expect(board.path.map((h) => h.id), ['alta', 'media1', 'media2', 'baja']);
  });

  test('el actual es el primero sin hacer; nulo si todo está hecho', () {
    final board = HabitsBoard(
      habits: [
        _h('baja', HabitPriority.low),
        _h('alta', HabitPriority.high, done: true),
      ],
    );
    expect(board.currentOnPath?.id, 'baja');
    expect(
      HabitsBoard(
        habits: [_h('a', HabitPriority.high, done: true)],
      ).currentOnPath,
      isNull,
    );
  });

  test('brokenStreak: el de mayor récord con racha en 0 y sin hacer hoy', () {
    Habit h(String id, int cur, int best, {bool done = false}) => Habit(
      id: id,
      name: id,
      type: HabitType.good,
      currentStreak: cur,
      bestStreak: best,
      doneToday: done,
    );
    expect(
      HabitsBoard(habits: [h('a', 3, 9), h('b', 0, 0)]).brokenStreak,
      isNull,
    );
    expect(
      HabitsBoard(
        habits: [h('a', 0, 4), h('b', 0, 12), h('c', 0, 20, done: true)],
      ).brokenStreak?.id,
      'b',
    );
  });
}
