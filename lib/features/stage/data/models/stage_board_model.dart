import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// Respuesta JSON de la RPC `stage_overview`
/// (supabase/migrations/013_stage.sql).
class StageBoardModel {
  const StageBoardModel(this.json);

  factory StageBoardModel.fromJson(Map<String, dynamic> json) =>
      StageBoardModel(json);

  final Map<String, dynamic> json;

  StageBoard toEntity() {
    final archive = json['archive'] as Map<String, dynamic>? ?? const {};
    return StageBoard(
      highlight: [
        for (final h in _list('highlight'))
          HighlightItem(
            id: h['id'] as String,
            title: h['title'] as String,
            bucket: StageBucket.values.byName(h['bucket'] as String),
            dueDate: _date(h['due_date']),
          ),
      ],
      highlightTotal: _int(json['highlight_total']),
      projects: [
        for (final p in _list('projects'))
          StageProject(
            id: p['id'] as String,
            title: p['title'] as String,
            urgency: StageUrgency.values.byName(p['urgency'] as String),
            skillName: p['skill_name'] as String?,
            goalTitle: p['goal_title'] as String?,
            endDate: _date(p['end_date']),
            tasksTotal: _int(p['tasks_total']),
            tasksDone: _int(p['tasks_done']),
            tasks: [
              for (final t in _cast(p['tasks']))
                StageTask(
                  id: t['id'] as String,
                  title: t['title'] as String,
                  done: t['done'] as bool? ?? false,
                ),
            ],
          ),
      ],
      areas: [
        for (final a in _list('areas'))
          StageArea(
            id: a['id'] as String,
            name: a['name'] as String,
            level: _int(a['level'], 1),
            openTasks: _int(a['open_tasks']),
            projects: _int(a['projects']),
            habits: _int(a['habits']),
          ),
      ],
      resources: [
        for (final r in _list('resources'))
          StageResource(
            id: r['id'] as String,
            title: r['title'] as String,
            url: r['url'] as String,
          ),
      ],
      archive: StageArchive(
        projects: _int(archive['projects']),
        goals: _int(archive['goals']),
        resources: _int(archive['resources']),
      ),
      skills: [
        for (final s in _list('skills'))
          StageLink(id: s['id'] as String, name: s['name'] as String),
      ],
      goals: [
        for (final g in _list('goals'))
          StageGoal(
            id: g['id'] as String,
            title: g['title'] as String,
            skillName: g['skill_name'] as String?,
            dueDate: _date(g['due_date']),
            bossHp: _int(g['boss_hp'], 100),
            bossMaxHp: _int(g['boss_max_hp'], 100),
            projects: _int(g['projects']),
            openTasks: _int(g['open_tasks']),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _list(String key) => _cast(json[key]);

  static List<Map<String, dynamic>> _cast(Object? value) =>
      (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();
}
