import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/tasks/data/models/tasks_board_model.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';

void main() {
  test('convierte la respuesta de missions_overview', () {
    final board = TasksBoardModel.fromJson({
      'missions': [
        {
          'id': 't1',
          'title': 'Preparar',
          'description': '  ',
          'priority': 'high',
          'bucket': 'urgent',
          'due_date': '2026-10-25T23:59:00+00:00',
          'xp_reward': 40,
          'coin_reward': 12,
          'skill_name': 'Estudio',
          'project_title': null,
          'goal_title': 'Aprobar',
          'subtasks_total': 2,
          'subtasks_done': 1,
        },
      ],
      'skills': [
        {'id': 's1', 'name': 'Estudio'},
      ],
      'projects': [
        {'id': 'p1', 'title': 'Curso', 'goal_id': 'g1'},
      ],
      'goals': [
        {'id': 'g1', 'title': 'Aprobar'},
      ],
    }).toEntity();

    final m = board.tasks.single;
    expect(m.priority, TaskPriority.high);
    expect(m.bucket, TaskBucket.urgent);
    expect(m.description, isNull);
    expect(m.dueDate, DateTime.utc(2026, 10, 25, 23, 59).toLocal());
    expect(
      [m.xpReward, m.coinReward, m.subtasksTotal, m.subtasksDone],
      [40, 12, 2, 1],
    );
    expect(m.goalTitle, 'Aprobar');
    expect(board.projects, [
      const TaskLink(id: 'p1', name: 'Curso', goalId: 'g1'),
    ]);
    expect(board.skills.single.name, 'Estudio');
    expect(board.goals.single.id, 'g1');
  });

  test('listas ausentes quedan vacías', () {
    expect(
      TasksBoardModel.fromJson({}).toEntity(),
      const TasksBoard(tasks: []),
    );
  });
}
