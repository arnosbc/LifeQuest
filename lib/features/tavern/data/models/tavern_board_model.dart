import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';

/// Respuesta JSON de la RPC `tavern_overview`
/// (supabase/migrations/019_tavern.sql).
class TavernBoardModel {
  const TavernBoardModel(this.json);

  factory TavernBoardModel.fromJson(Map<String, dynamic> json) =>
      TavernBoardModel(json);

  final Map<String, dynamic> json;

  TavernBoard toEntity() => TavernBoard(
    npcs: [
      for (final n in _list(json['npcs']))
        Npc(
          id: n['id'] as String,
          name: n['name'] as String,
          skillName: n['skill_name'] as String? ?? '',
          frequency:
              NpcFrequency.values.asNameMap()[n['frequency']] ??
              NpcFrequency.weekly,
          nobleMission: n['noble_mission'] as String?,
          freeAt: switch (n['free_at']) {
            final String at => DateTime.parse(at).toLocal(),
            _ => null,
          },
          openMission: switch (n['open_mission']) {
            final Map<String, dynamic> m => NpcMission(
              id: m['id'] as String,
              title: m['title'] as String,
              description: m['description'] as String?,
              xpReward: _int(m['xp_reward']),
            ),
            _ => null,
          },
          completed: _int(n['completed']),
          documents: [
            for (final d in _list(n['documents']))
              NpcDocument(id: d['id'] as String, title: d['title'] as String),
          ],
        ),
    ],
    npcLimit: _int(json['npc_limit'], 3),
    instantCost: _int(json['instant_cost'], 15),
    coins: _int(json['coins']),
    skills: [
      for (final s in _list(json['skills']))
        TavernSkill(id: s['id'] as String, name: s['name'] as String),
    ],
  );

  static List<Map<String, dynamic>> _list(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;
}
