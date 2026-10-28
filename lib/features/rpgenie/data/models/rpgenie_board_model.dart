import 'package:proyecto_movil/features/rpgenie/domain/entities/current_mission.dart';

/// Respuesta JSON de la RPC `current_mission`
/// (supabase/migrations/022_rpgenie.sql).
class RpgenieBoardModel {
  const RpgenieBoardModel(this.json);

  factory RpgenieBoardModel.fromJson(Map<String, dynamic> json) =>
      RpgenieBoardModel(json);

  final Map<String, dynamic> json;

  RpgenieBoard toEntity() => RpgenieBoard(
    mission: switch (json['mission']) {
      final Map<String, dynamic> m => CurrentMission(
        id: m['id'] as String,
        title: m['title'] as String,
        reason:
            MissionReason.values.asNameMap()[m['reason']] ?? MissionReason.next,
        dueDate: switch (m['due_date']) {
          final String at => DateTime.parse(at).toLocal(),
          _ => null,
        },
        xpReward: _int(m['xp_reward']),
        coinReward: _int(m['coin_reward']),
        skillName: m['skill_name'] as String?,
        goalTitle: m['goal_title'] as String?,
        projectTitle: m['project_title'] as String?,
      ),
      _ => null,
    },
    openCount: _int(json['open_count']),
    skippedCount: _int(json['skipped_count']),
  );

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;
}
