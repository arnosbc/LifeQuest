import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';

/// Respuesta JSON de la RPC `missions_overview`
/// (supabase/migrations/010_missions.sql, campos de agenda en 032).
class TasksBoardModel {
  const TasksBoardModel(this.json);

  factory TasksBoardModel.fromJson(Map<String, dynamic> json) =>
      TasksBoardModel(json);

  final Map<String, dynamic> json;

  TasksBoard toEntity() => TasksBoard(
    tasks: [
      for (final m in _list('missions'))
        Task(
          id: m['id'] as String,
          title: m['title'] as String,
          description: _text(m['description']),
          priority: TaskPriority.values.byName(m['priority'] as String),
          bucket: TaskBucket.values.byName(m['bucket'] as String),
          dueDate: _date(m['due_date']),
          xpReward: _int(m['xp_reward']),
          coinReward: _int(m['coin_reward']),
          skillName: _text(m['skill_name']),
          projectTitle: _text(m['project_title']),
          goalTitle: _text(m['goal_title']),
          subtasksTotal: _int(m['subtasks_total']),
          subtasksDone: _int(m['subtasks_done']),
          scheduledAt: _date(m['scheduled_at']),
          estimatedMinutes: (m['estimated_minutes'] as num?)?.toInt(),
          reminderMinutes: (m['reminder_minutes'] as num?)?.toInt(),
          repeatRule: _text(m['repeat_rule']),
          focusMinutes: _int(m['focus_minutes']),
        ),
    ],
    skills: [
      for (final s in _list('skills'))
        TaskLink(id: s['id'] as String, name: s['name'] as String),
    ],
    projects: [
      for (final p in _list('projects'))
        TaskLink(
          id: p['id'] as String,
          name: p['title'] as String,
          goalId: p['goal_id'] as String?,
        ),
    ],
    goals: [
      for (final g in _list('goals'))
        TaskLink(id: g['id'] as String, name: g['title'] as String),
    ],
  );

  List<Map<String, dynamic>> _list(String key) =>
      (json[key] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toLocal() : null;

  static int _int(Object? value) => (value as num?)?.toInt() ?? 0;

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
