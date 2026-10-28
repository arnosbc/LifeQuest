import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';
import 'package:proyecto_movil/features/vision/domain/repositories/vision_repository.dart';

/// Lee la visión y las Metas y Proyectos que se pueden vincular.
class GetVisionBoard implements UseCase<VisionBoard, NoParams> {
  const GetVisionBoard(this._repository);

  final VisionRepository _repository;

  @override
  Future<Either<Failure, VisionBoard>> call(NoParams params) =>
      _repository.getBoard();
}
