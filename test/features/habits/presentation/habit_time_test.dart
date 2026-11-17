import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/habits/data/models/habits_board_model.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_time.dart';

void main() {
  test('habitTimeLabel muestra la hora en formato de 12 horas', () {
    expect(habitTimeLabel('20:00'), '8:00 p. m.');
    expect(habitTimeLabel('07:05'), '7:05 a. m.');
    expect(habitTimeLabel('00:30'), '12:30 a. m.');
    expect(habitTimeLabel('12:00'), '12:00 p. m.');
  });

  test('el modelo lee la hora del hábito (071) y null si no tiene', () {
    final board = HabitsBoardModel({
      'habits': [
        {'id': 'h1', 'name': 'Leer', 'type': 'good', 'reminder_time': '20:00'},
        {'id': 'h2', 'name': 'Meditar', 'type': 'good'},
      ],
    }).toEntity();
    expect(board.habits.map((h) => h.reminderTime), ['20:00', null]);
  });
}
