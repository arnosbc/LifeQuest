import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/focus/data/datasources/focus_remote_datasource.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';
import 'package:proyecto_movil/core/errors/supabase_guard.dart';

class FocusRepositoryImpl implements FocusRepository {
  const FocusRepositoryImpl(this._remote);

  final FocusRemoteDataSource _remote;

  @override
  Future<Either<Failure, FocusBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, String>> start({
    required int totalMinutes,
    required int cycleMinutes,
    required List<String> taskIds,
  }) => _run(
    () => _remote.start(
      totalMinutes: totalMinutes,
      cycleMinutes: cycleMinutes,
      taskIds: taskIds,
    ),
  );

  @override
  Future<Either<Failure, Unit>> completeCycle({
    required String sessionId,
    required String taskId,
  }) => _run(() async {
    await _remote.completeCycle(sessionId: sessionId, taskId: taskId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> completeTask(String taskId) => _run(() async {
    await _remote.completeTask(taskId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> addStep({
    required String taskId,
    required String title,
  }) => _run(() async {
    await _remote.addStep(taskId: taskId, title: title);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> schedule({
    required String taskId,
    required DateTime at,
  }) => _run(() async {
    await _remote.schedule(taskId: taskId, at: at);
    return unit;
  });

  @override
  Future<Either<Failure, FocusSummary>> end(String sessionId) =>
      _run(() async => (await _remote.end(sessionId)).toEntity());

  @override
  Future<Either<Failure, Unit>> setResumeNote({
    required String taskId,
    required String note,
  }) => _run(() async {
    await _remote.setResumeNote(taskId: taskId, note: note);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> captureDistraction(String text) =>
      _run(() async {
        await _remote.captureDistraction(text);
        return unit;
      });

  @override
  Future<Either<Failure, List<String>>> recallQuestions({
    required String title,
    required List<String> notes,
  }) => _run(() => _remote.recallQuestions(title: title, notes: notes));

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) =>
      runGuarded(action, (error) => _messageFor(error.code));

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(String? code) => switch (code) {
    'session_already_open' =>
      'Ya tienes una sesión de foco en curso. Desliza para retomarla.',
    'invalid_duration' =>
      'La sesión dura de 30 min a 8 h, en pasos de 30, y cabe al menos un ciclo.',
    'no_tasks' => 'Elige al menos una tarea para la sesión.',
    'session_task_limit' => 'Una sesión admite hasta 5 tareas.',
    'task_not_found' =>
      'Alguna tarea ya no está abierta. Desliza para actualizar.',
    'cycle_not_finished' => 'Al ciclo aún le falta un poco. Sigue concentrado.',
    'session_cycles_exhausted' =>
      'Completaste todos los ciclos de esta sesión. ¡Gran trabajo!',
    'session_not_found' || 'session_not_active' =>
      'Esta sesión ya terminó. Puedes empezar otra cuando quieras.',
    'task_not_open' => 'Esa tarea ya estaba cerrada. ¡Una menos!',
    'ai_disabled' => 'Las preguntas usan la IA: actívala en Ajustes. Tus notas siguen aquí.',
    'ai_limit' => 'Usaste las llamadas de IA de hoy. Repasa con tus notas.',
    'invalid_note' => 'La nota puede tener hasta 500 caracteres.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
