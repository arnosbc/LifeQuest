import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';

const goodHabit = Habit(
  id: 'h1',
  name: 'Leer',
  type: HabitType.good,
  currentStreak: 3,
  week: [false, false, false, false, true, true, true],
);

const badHabit = Habit(
  id: 'h2',
  name: 'Pantallas de noche',
  type: HabitType.bad,
  hpPenalty: 5,
  todayCount: 1,
);

const habitsBoard = HabitsBoard(habits: [goodHabit, badHabit], weekXp: 30);
const emptyHabitsBoard = HabitsBoard(habits: []);
const newHabit = NewHabit(name: 'Beber agua', type: HabitType.good);
