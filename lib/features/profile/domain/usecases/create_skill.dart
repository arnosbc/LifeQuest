import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';

/// Crea una skill con el nombre dado (String).
class CreateSkill implements UseCase<Unit, String> {
  const CreateSkill(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String name) =>
      _repository.createSkill(name);
}
