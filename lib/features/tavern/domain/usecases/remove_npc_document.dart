import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Quita un documento de contexto del NPC (y su archivo).
class RemoveNpcDocument implements UseCase<Unit, String> {
  const RemoveNpcDocument(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String documentId) =>
      _repository.removeDocument(documentId);
}
