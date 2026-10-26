import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/missions/data/models/missions_board_model.dart';
import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';

void main() {
  test('convierte la respuesta de missions_overview', () {
    final board = MissionsBoardModel.fromJson({
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

    final m = board.missions.single;
    expect(m.priority, MissionPriority.high);
    expect(m.bucket, MissionBucket.urgent);
    expect(m.description, isNull);
    expect(m.dueDate, DateTime.utc(2026, 10, 25, 23, 59).toLocal());
    expect(
      [m.xpReward, m.coinReward, m.subtasksTotal, m.subtasksDone],
      [40, 12, 2, 1],
    );
    expect(m.goalTitle, 'Aprobar');
    expect(board.projects, [
      const MissionLink(id: 'p1', name: 'Curso', goalId: 'g1'),
    ]);
    expect(board.skills.single.name, 'Estudio');
    expect(board.goals.single.id, 'g1');
  });

  test('listas ausentes quedan vacías', () {
    expect(
      MissionsBoardModel.fromJson({}).toEntity(),
      const MissionsBoard(missions: []),
    );
  });
}
