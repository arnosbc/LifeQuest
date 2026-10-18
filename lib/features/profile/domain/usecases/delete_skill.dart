import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';

/// Elimina una skill por su id (String).
class DeleteSkill implements UseCase<Unit, String> {
  const DeleteSkill(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String skillId) =>
      _repository.deleteSkill(skillId);
}
