import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Crea un proyecto desde Quick Add.
class CreateProject implements UseCase<Unit, NewProject> {
  const CreateProject(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NewProject params) =>
      _repository.createProject(params);
}
