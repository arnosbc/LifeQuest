import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Unit;
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/reminder_actions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_sheet.dart';
import 'package:proyecto_movil/core/widgets/show_lifequest_message.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/break_down_task.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';
import 'package:proyecto_movil/features/assistant/presentation/widgets/capture_view.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_goal.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/get_stage_board.dart';
import 'package:proyecto_movil/features/stage/presentation/widgets/quick_add_sheets.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/create_task.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/get_tasks_board.dart';
import 'package:proyecto_movil/features/tasks/presentation/widgets/create_task_sheet.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Hoja «Crear» (barra de Hoy y botón flotante): tarea, proyecto o meta
/// escribiendo o dictando, con IA si está activa, o con el formulario
/// completo. Devuelve true si se guardó algo; los avisos ya se reprogramaron.
/// [listen]: abre dictando. [sharedText]: lo que llegó de otra app (por
/// defecto va a la Bandeja).
Future<bool> openCaptureSheet(
  BuildContext context, {
  bool listen = false,
  String? sharedText,
}) async {
  // Áreas e historial para sugerir el área; si falla, la hoja sigue sin ellas.
  final board = (await sl<GetTasksBoard>()(const NoParams())).getRight().toNullable();
  final areas = [
    for (final s in board?.skills ?? const <TaskLink>[])
      DraftArea(id: s.id, name: s.name),
  ];
  final history = [
    for (final t in board?.tasks ?? const <Task>[])
      if (t.skillName case final name?) (title: t.title, areaName: name),
  ];
  if (!context.mounted) return false;
  final result = await showQuestlySheet<Object>(
    context,
    title: sharedText == null ? 'Crear' : 'Guardar lo compartido',
    child: BlocProvider(
      create: (_) => sl<CaptureBloc>()
        ..add(CaptureAreasLoaded(areas, history)),
      child: Builder(
        builder: (sheet) => CaptureView(
          startListening: listen,
          initialText: sharedText,
          preferInbox: sharedText != null,
          onOpenForm: (kind) => Navigator.pop(sheet, kind),
          areas: areas,
        ),
      ),
    ),
  );
  if (!context.mounted) return false;
  final saved = switch (result) {
    final CaptureKind kind => await _openForm(context, kind),
    _ => result == true,
  };
  if (saved) ReminderActions.sync();
  return saved;
}

/// Formulario completo de cada feature. Une Asistente con Tareas y Proyectos,
/// por eso vive en app/.
Future<bool> _openForm(BuildContext context, CaptureKind kind) async {
  Future<T?> sheet<T>(Widget child) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );

  Future<bool> done(Either<Failure, Unit> result, String message) async {
    if (!context.mounted) return false;
    showLifeQuestMessage(
      context,
      result.match((failure) => failure.message, (_) => message),
    );
    return result.isRight();
  }

  /// Datos del formulario (áreas, proyectos, metas) o null tras avisar.
  Future<T?> load<T>(Future<Either<Failure, T>> request) async {
    final result = await request;
    if (result.getLeft().toNullable() case final failure?
        when context.mounted) {
      showLifeQuestMessage(context, failure.message);
    }
    return context.mounted ? result.getRight().toNullable() : null;
  }

  if (kind == CaptureKind.task) {
    final board = await load(sl<GetTasksBoard>()(const NoParams()));
    if (board == null) return false;
    final result = await sheet<CreateTaskResult>(
      CreateTaskSheet(board: board, suggestSteps: sl<BreakDownTask>().titles),
    );
    if (result == null) return false;
    final saved = await done(
      await sl<CreateTask>()(result.task),
      'Tarea creada.',
    );
    if (saved && result.startFocus && context.mounted) {
      context.go(RoutePaths.focus);
    }
    return saved;
  }

  final stage = await load(sl<GetStageBoard>()(DateTime.now()));
  if (stage == null) return false;
  if (kind == CaptureKind.project) {
    final project = await sheet<NewProject>(
      CreateProjectSheet(skills: stage.skills, goals: stage.goalLinks),
    );
    if (project == null) return false;
    return done(
      await sl<CreateProject>()(project),
      'Proyecto creado. Añádele tareas para avanzar.',
    );
  }
  final goal = await sheet<NewGoal>(CreateGoalSheet(skills: stage.skills));
  if (goal == null) return false;
  return done(
    await sl<CreateGoal>()(goal),
    'Meta creada. Vincúlale tareas para avanzar.',
  );
}
