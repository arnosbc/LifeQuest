import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/assistant/data/datasources/assistant_remote_datasource.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/interpretation.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  const AssistantRepositoryImpl(this._remote);

  final AssistantRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<PlanTask>>> getOpenTasks() => _run(
    () async => [for (final m in await _remote.getOpenTasks()) m.toEntity()],
  );

  // shortcut: un schedule_task por bloque (≤ unas 20 tareas al día); pasar a
  // una RPC por lote si la agenda crece.
  @override
  Future<Either<Failure, Unit>> applyBlocks(List<ProposedBlock> blocks) =>
      _run(() async {
        for (final block in blocks) {
          await _remote.schedule(block);
        }
        return unit;
      });

  @override
  Future<Either<Failure, AiStatus>> getAiStatus() => _run(_remote.aiStatus);

  @override
  Future<Either<Failure, TaskDraft>> parseWithAi(String text, DateTime now) =>
      _run(() async => (await _remote.parse(text, now)).toEntity());

  @override
  Future<Either<Failure, List<String>>> breakdown(String title) =>
      _run(() => _remote.breakdown(title));

  @override
  Future<Either<Failure, Unit>> createTask(
    TaskDraft draft,
    List<DraftStep> steps,
  ) => _run(() async {
    await _remote.createTask(draft, steps);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> saveToInbox(String text) => _run(() async {
    await _remote.saveToInbox(text);
    return unit;
  });

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
      return Left(
        ServerFailure(switch (error.code) {
          'task_not_found' =>
            'Una tarea cambió mientras planeabas. Vuelve a abrir la propuesta.',
          'ai_limit' =>
            'Usaste las llamadas de IA de hoy. Lo entendí con las reglas.',
          'ai_disabled' =>
            'La IA está apagada en Ajustes. Lo entendí con las reglas.',
          'invalid_title' =>
            'Dale a tu tarea un nombre de hasta 200 caracteres.',
          'invalid_content' => 'Escribe algo para guardarlo en la Bandeja.',
          final code? when code.startsWith('gemini') || code == 'sin_pasos' =>
            'La IA no respondió. Inténtalo de nuevo en un momento.',
          _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
        }),
      );
    }
  }
}
