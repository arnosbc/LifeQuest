import 'package:proyecto_movil/features/missions/domain/entities/mission.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';

/// Respuesta JSON de la RPC `missions_overview`
/// (supabase/migrations/010_missions.sql).
class MissionsBoardModel {
  const MissionsBoardModel(this.json);

  factory MissionsBoardModel.fromJson(Map<String, dynamic> json) =>
      MissionsBoardModel(json);

  final Map<String, dynamic> json;

  MissionsBoard toEntity() => MissionsBoard(
    missions: [
      for (final m in _list('missions'))
        Mission(
          id: m['id'] as String,
          title: m['title'] as String,
          description: _text(m['description']),
          priority: MissionPriority.values.byName(m['priority'] as String),
          bucket: MissionBucket.values.byName(m['bucket'] as String),
          dueDate: m['due_date'] == null
              ? null
              : DateTime.parse(m['due_date'] as String).toLocal(),
          xpReward: _int(m['xp_reward']),
          coinReward: _int(m['coin_reward']),
          skillName: _text(m['skill_name']),
          projectTitle: _text(m['project_title']),
          goalTitle: _text(m['goal_title']),
          subtasksTotal: _int(m['subtasks_total']),
          subtasksDone: _int(m['subtasks_done']),
        ),
    ],
    skills: [
      for (final s in _list('skills'))
        MissionLink(id: s['id'] as String, name: s['name'] as String),
    ],
    projects: [
      for (final p in _list('projects'))
        MissionLink(
          id: p['id'] as String,
          name: p['title'] as String,
          goalId: p['goal_id'] as String?,
        ),
    ],
    goals: [
      for (final g in _list('goals'))
        MissionLink(id: g['id'] as String, name: g['title'] as String),
    ],
  );

  List<Map<String, dynamic>> _list(String key) =>
      (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
