import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Lee el centro de mando; el parámetro es la hora local.
class GetStageBoard implements UseCase<StageBoard, DateTime> {
  const GetStageBoard(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, StageBoard>> call(DateTime params) =>
      _repository.getBoard(params);
}
