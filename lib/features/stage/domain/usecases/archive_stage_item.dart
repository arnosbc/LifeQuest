import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Manda un proyecto o un recurso al Archivo.
class ArchiveStageItem implements UseCase<Unit, ArchiveStageItemParams> {
  const ArchiveStageItem(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ArchiveStageItemParams params) =>
      _repository.archive(kind: params.kind, id: params.id);
}

class ArchiveStageItemParams extends Equatable {
  const ArchiveStageItemParams({required this.kind, required this.id});

  final StageItemKind kind;
  final String id;

  @override
  List<Object?> get props => [kind, id];
}
