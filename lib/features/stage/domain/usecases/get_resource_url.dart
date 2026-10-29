import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Enlace para abrir un documento guardado: el bucket es privado, así que se
/// pide un enlace temporal firmado.
class GetResourceUrl implements UseCase<String, StageResource> {
  const GetResourceUrl(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, String>> call(StageResource params) =>
      _repository.resourceUrl(params);
}
