import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';

/// Respuesta JSON de la RPC `goals_overview`
/// (supabase/migrations/021_boss_fight.sql).
class GoalsBoardModel {
  const GoalsBoardModel(this.json);

  factory GoalsBoardModel.fromJson(Map<String, dynamic> json) =>
      GoalsBoardModel(json);

  final Map<String, dynamic> json;

  static const _status = {
    'not_started': GoalStatus.notStarted,
    'in_progress': GoalStatus.inProgress,
    'completed': GoalStatus.completed,
    'expired': GoalStatus.expired,
  };

  GoalsBoard toEntity() => GoalsBoard(
    goals: [
      for (final g in _list(json['goals']))
        BossGoal(
          id: g['id'] as String,
          title: g['title'] as String,
          status: _status[g['status']] ?? GoalStatus.notStarted,
          dueDate: _date(g['due_date']),
          skillName: g['skill_name'] as String?,
          maxHp: _int(g['boss_max_hp'], 100),
          currentHp: _int(g['boss_current_hp'], 100),
          smart: switch (g['smart']) {
            final Map<String, dynamic> s => SmartSheet(
              specific: s['specific'] as String?,
              measurable: s['measurable'] as String?,
              achievable: s['achievable'] as String?,
              relevant: s['relevant'] as String?,
              timebound: s['timebound'] as String?,
            ),
            _ => const SmartSheet(),
          },
          attacks: [
            for (final a in _list(g['attacks']))
              BossAttack(
                kind: a['kind'] == 'project'
                    ? AttackKind.project
                    : AttackKind.task,
                id: a['id'] as String,
                title: a['title'] as String,
                damage: _int(a['damage']),
              ),
          ],
          hits: [
            for (final h in _list(g['hits']))
              BossHit(
                title: h['title'] as String,
                damage: _int(h['damage']),
                at: _date(h['at']),
              ),
          ],
        ),
    ],
    victoryXp: _int(json['victory_xp'], 300),
    victoryCoins: _int(json['victory_coins'], 90),
  );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;

  static List<Map<String, dynamic>> _list(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;
}
