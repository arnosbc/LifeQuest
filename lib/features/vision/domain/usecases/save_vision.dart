import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/vision/domain/repositories/vision_repository.dart';

/// Guarda el texto de la visión.
class SaveVision implements UseCase<Unit, String> {
  const SaveVision(this._repository);

  final VisionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) => _repository.save(params);
}
