import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/guided_task/data/datasources/guided_task_remote_datasource.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_evidence.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_review.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

class GuidedTaskRepositoryImpl implements GuidedTaskRepository {
  const GuidedTaskRepositoryImpl(this._remote);

  final GuidedTaskRemoteDataSource _remote;

  @override
  Future<Either<Failure, GuidedTask>> getTask(String taskId) =>
      _run(() async => (await _remote.getTask(taskId)).toEntity());

  @override
  Future<Either<Failure, bool>> toggleStep(String stepId) =>
      _run(() => _remote.toggleStep(stepId));

  @override
  Future<Either<Failure, Unit>> completeTask(String taskId) => _run(() async {
    await _remote.completeTask(taskId);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> setSteps(String taskId, List<String> steps) =>
      _run(() async {
        await _remote.setSteps(taskId, steps);
        return unit;
      });

  @override
  Future<Either<Failure, GuidedStepReview>> reviewStep(
    String stepId,
    List<GuidedStepEvidence> evidence,
  ) =>
      _run(() async => (await _remote.reviewStep(stepId, evidence)).toEntity());

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error.code)));
    } on FormatException {
      return const Left(
        ServerFailure(
          'No pudimos interpretar la revisión de IA. Inténtalo más tarde.',
        ),
      );
    }
  }

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(String? code) => switch (code) {
    'task_not_found' =>
      'No encontramos esa tarea. Vuelve atrás y ábrela de nuevo.',
    'task_not_open' => 'Esta tarea ya está completada. ¡Bien hecho!',
    'focus_required' =>
      'Las tareas se hacen en Modo Foco. Empieza una sesión con esta tarea.',
    'guide_locked' =>
      'Ya cobraste un paso de esta tarea: sus pasos no se pueden cambiar.',
    'step_order_required' =>
      'Completa el paso actual antes de avanzar al siguiente.',
    'task_steps_pending' =>
      'Completa los pasos de esta tarea para poder terminarla.',
    'verification_unavailable' =>
      'No pudimos revisar los archivos ahora. Inténtalo de nuevo más tarde.',
    'invalid_evidence' =>
      'Revisa los archivos: se aceptan imágenes, PDF, DOCX, TXT y Markdown '
          'de hasta 10 MB en total.',
    'unsupported_type' =>
      'Ese formato no es compatible. Elige una imagen, PDF, DOCX, TXT o Markdown.',
    'step_not_found' =>
      'No encontramos ese paso. Vuelve atrás y ábrelo de nuevo.',
    'invalid_guide' => 'Escribe al menos un paso.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
