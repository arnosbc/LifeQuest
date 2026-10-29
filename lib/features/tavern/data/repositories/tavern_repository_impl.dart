import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/tavern/data/datasources/tavern_remote_datasource.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

class TavernRepositoryImpl implements TavernRepository {
  const TavernRepositoryImpl(this._remote);

  final TavernRemoteDataSource _remote;

  @override
  Future<Either<Failure, TavernBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, Unit>> createNpc(NewNpc npc) =>
      _done(() => _remote.createNpc(npc));

  @override
  Future<Either<Failure, NpcMissionSuggestion?>> suggestMission(String npcId) =>
      _run(() => _remote.suggestMission(npcId));

  @override
  Future<Either<Failure, Unit>> acceptMission({
    required String npcId,
    required String title,
    String? description,
  }) => _done(
    () => _remote.acceptMission(npcId, title, description: description),
  );

  @override
  Future<Either<Failure, Unit>> completeMission(String taskId) =>
      _done(() => _remote.completeMission(taskId));

  @override
  Future<Either<Failure, Unit>> addDocument(NewNpcDocument document) =>
      _done(() => _remote.addDocument(document));

  @override
  Future<Either<Failure, Unit>> removeDocument(String documentId) =>
      _done(() => _remote.removeDocument(documentId));

  @override
  Future<Either<Failure, Unit>> renameNpc(String npcId, String name) =>
      _done(() => _remote.renameNpc(npcId, name));

  @override
  Future<Either<Failure, Unit>> deleteNpc(String npcId) =>
      _done(() => _remote.deleteNpc(npcId));

  Future<Either<Failure, Unit>> _done(Future<void> Function() action) =>
      _run(() async {
        await action();
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
          'suggestion_failed' =>
            'RPGenie no pudo crear la misión ahora '
                '(código ${error.statusCode}). Inténtalo en un rato.',
          'document_failed' =>
            'RPGenie no pudo leer el documento ahora '
                '(código ${error.statusCode}). Inténtalo en un rato.',
          _ => _messageFor(error.code),
        }),
      );
    }
  }

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(String? code) => switch (code) {
    'npc_limit_reached' =>
      'Tu Taverna está llena. Mejora el Estandarte del Refugio para recibir más NPCs.',
    'invalid_name' => 'Dale a tu NPC un nombre de hasta 60 caracteres.',
    'skill_not_found' => 'Elige la skill que entrenará este NPC.',
    'invalid_noble_mission' =>
      'Escribe la noble misión (hasta 300 caracteres): es el tema de sus misiones.',
    'invalid_title' => 'Escribe la misión en hasta 200 caracteres.',
    'invalid_description' =>
      'La guía de la misión es demasiado larga. Pídela de nuevo en un rato.',
    'npc_mission_open' =>
      'Este NPC ya te dio una misión. Cúmplela y te propondrá otra.',
    'npc_not_found' => 'No encontramos ese NPC. Desliza para actualizar.',
    'not_enough_coins' =>
      'Aún te faltan Monedas para pedirla ya. Pronto será gratis.',
    'npc_document_limit' =>
      'Este NPC ya tiene ${NewNpcDocument.maxPerNpc} documentos. '
          'Quita uno para adjuntar otro.',
    'unsupported_type' => 'Sube el documento en PDF, Word (.docx) o Markdown.',
    'empty_document' || 'unreadable_document' =>
      'No logramos leer el documento. Prueba a guardarlo como PDF.',
    'upload_failed' =>
      'No se pudo subir el archivo. Revisa tu conexión y reintenta.',
    'document_not_found' =>
      'Ese documento ya no está. Desliza para actualizar.',
    'task_not_found' || 'task_not_open' =>
      'Esa misión ya no está abierta. Desliza para actualizar.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
