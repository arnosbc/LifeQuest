import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/home/data/models/home_dashboard_model.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

import '../../home_fixtures.dart';

void main() {
  test('convierte el JSON de la RPC en la entidad', () {
    expect(HomeDashboardModel.fromJson(dashboardJson).toEntity(), dashboard);
  });

  test('sin estadísticas, tarea ni hábitos usa los valores por defecto', () {
    final entity = HomeDashboardModel.fromJson(const {
      'display_name': '  ',
      'character_class': null,
      'level': null,
      'priority_mission': null,
      'habits': null,
      'habits_done': 0,
    }).toEntity();

    expect(entity, emptyDashboard);
  });

  test('hábito con hora y meta quieta de day_agenda (046)', () {
    final entity = HomeDashboardModel.fromJson(const {
      'day': '2026-11-16',
      'habits': [
        {'id': 'h1', 'name': 'Leer', 'done': false},
        {'id': 'h2', 'name': 'Correr', 'done': false},
      ],
      'agenda': {
        'habit_times': [
          {'id': 'h1', 'reminder_time': '21:15:00'},
        ],
        'stalled_goal': {
          'id': 'g1',
          'title': 'Correr 10 km',
          'next_task': {'id': 't1', 'title': 'Correr 3 km'},
        },
      },
    }).toEntity();

    expect(entity.habits.first.reminderAt, DateTime(2026, 11, 16, 21, 15));
    expect(entity.habits.last.reminderAt, isNull);
    expect(
      entity.stalledGoal,
      const StalledGoal(
        id: 'g1',
        title: 'Correr 10 km',
        nextTaskId: 't1',
        nextTaskTitle: 'Correr 3 km',
      ),
    );
  });
}
