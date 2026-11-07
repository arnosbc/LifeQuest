import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';

/// Borra un proyecto, una meta o un recurso (lo completado no se borra).
class DeleteStageItem implements UseCase<Unit, ArchiveStageItemParams> {
  const DeleteStageItem(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ArchiveStageItemParams params) =>
      _repository.delete(kind: params.kind, id: params.id);
}
