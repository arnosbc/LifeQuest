import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/features/assistant/data/models/plan_task_model.dart';
import 'package:proyecto_movil/features/assistant/data/models/task_draft_model.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/interpretation.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

/// RPCs que usa el Asistente. Lanza [ServerException] o [NetworkException].
abstract class AssistantRemoteDataSource {
  Future<List<PlanTaskModel>> getOpenTasks();

  Future<void> schedule(ProposedBlock block);

  Future<AiStatus> aiStatus();

  Future<TaskDraftModel> parse(String text, DateTime now);

  Future<List<String>> breakdown(String title, AiContext ai);

  /// Devuelve el id de lo creado (para adjuntarle recursos).
  Future<String> createTask(TaskDraft draft, List<DraftStep> steps);

  Future<({String title, SmartGoal smart, List<String> steps})> planGoal(
    String text,
  );

  Future<String> createProject(TaskDraft draft, List<DraftStep> steps);

  Future<String> createGoal(
    TaskDraft draft,
    SmartGoal smart,
    List<DraftStep> steps,
  );

  Future<void> saveToInbox(String text);
}

class AssistantRemoteDataSourceImpl implements AssistantRemoteDataSource {
  const AssistantRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  /// `missions_overview` (010, agenda en 032) ya trae las tareas abiertas.
  @override
  Future<List<PlanTaskModel>> getOpenTasks() => guardSupabase(() async {
    final json = await _client.rpc<Map<String, dynamic>>('missions_overview');
    return [
      for (final m in json['missions'] as List<dynamic>? ?? const [])
        PlanTaskModel(m as Map<String, dynamic>),
    ];
  });

  @override
  Future<void> schedule(ProposedBlock block) => guardSupabase(
    () => _client.rpc<void>(
      'schedule_task',
      params: {
        'p_task_id': block.taskId,
        'p_at': block.start.toUtc().toIso8601String(),
        'p_minutes': block.minutes,
      },
    ),
  );

  @override
  Future<AiStatus> aiStatus() => guardSupabase(() async {
    final json = await _client.rpc<Map<String, dynamic>>('assistant_status');
    return AiStatus(
      enabled: json['ai_enabled'] as bool? ?? false,
      callsLeft: (json['calls_left'] as num?)?.toInt() ?? 0,
    );
  });

  @override
  Future<TaskDraftModel> parse(String text, DateTime now) =>
      guardSupabase(() async {
        final res = await _client.functions.invoke(
          'assistant',
          body: {
            'mode': 'parse',
            'text': text,
            'now': TaskDraftModel.localIso(now),
          },
        );
        return TaskDraftModel(res.data as Map<String, dynamic>, text.trim());
      });

  @override
  Future<List<String>> breakdown(String title, AiContext ai) =>
      guardSupabase(() async {
    final res = await _client.functions.invoke(
      'assistant',
      body: {
        'mode': 'breakdown',
        'title': title,
        if (ai.paths.isNotEmpty) 'paths': ai.paths,
        if (ai.context.isNotEmpty) 'context': ai.context,
      },
    );
    return [
      for (final s in (res.data as Map<String, dynamic>)['steps'] as List)
        if (s is String && s.trim().isNotEmpty) s.trim(),
    ];
  });

  /// La tarea con `create_task`; los pasos, como subtareas con fecha (insert
  /// directo: RLS y grants de columna de 003; la recompensa la pone el trigger).
  @override
  Future<String> createTask(TaskDraft draft, List<DraftStep> steps) =>
      guardSupabase(() async {
        final res = await _client.rpc<Map<String, dynamic>>(
          'create_task',
          params: TaskDraftModel.toParams(draft),
        );
        final id = res['id'] as String;
        if (steps.isEmpty) return id;
        final uid = _client.auth.currentUser?.id;
        await _client.from('tasks').insert([
          for (final s in steps)
            {
              'user_id': uid,
              'parent_task_id': res['id'],
              'title': s.title,
              'due_date': s.due.toUtc().toIso8601String(),
            },
        ]);
        return id;
      });

  @override
  Future<({String title, SmartGoal smart, List<String> steps})> planGoal(
    String text,
  ) => guardSupabase(() async {
    final res = await _client.functions.invoke(
      'assistant',
      body: {'mode': 'goal', 'text': text},
    );
    final json = res.data as Map<String, dynamic>;
    return (
      title: json['title'] as String,
      smart: SmartGoal(
        specific: json['specific'] as String,
        measurable: json['measurable'] as String,
        achievable: json['achievable'] as String,
        relevant: json['relevant'] as String,
      ),
      steps: [
        for (final s in json['steps'] as List)
          if (s is String && s.trim().isNotEmpty) s.trim(),
      ],
    );
  });

  @override
  Future<String> createProject(TaskDraft draft, List<DraftStep> steps) =>
      guardSupabase(() async {
        final id = await _client.rpc<String>(
          'create_project',
          params: {'p_title': draft.title, 'p_end_date': _date(draft.dueDate)},
        );
        await _insertSteps(steps, {'project_id': id});
        return id;
      });

  @override
  Future<String> createGoal(
    TaskDraft draft,
    SmartGoal smart,
    List<DraftStep> steps,
  ) => guardSupabase(() async {
    final id = await _client.rpc<String>(
      'create_goal',
      params: {
        'p_title': draft.title,
        'p_specific': smart.specific,
        'p_measurable': smart.measurable,
        'p_achievable': smart.achievable,
        'p_relevant': smart.relevant,
        'p_due_date': _date(draft.dueDate),
      },
    );
    await _insertSteps(steps, {'goal_id': id});
    return id;
  });

  /// Pasos como tareas raíz vinculadas (insert directo como en [createTask]).
  Future<void> _insertSteps(
    List<DraftStep> steps,
    Map<String, String> link,
  ) async {
    if (steps.isEmpty) return;
    final uid = _client.auth.currentUser?.id;
    await _client.from('tasks').insert([
      for (final s in steps)
        {
          'user_id': uid,
          ...link,
          'title': s.title,
          'due_date': s.due.toUtc().toIso8601String(),
        },
    ]);
  }

  static String? _date(DateTime? d) => d == null
      ? null
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  @override
  Future<void> saveToInbox(String text) => guardSupabase(
    () => _client.rpc<void>('capture_thought', params: {'p_content': text}),
  );
}
