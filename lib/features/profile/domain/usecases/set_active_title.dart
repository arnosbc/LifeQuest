import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';

/// Elige el título ganado que se luce bajo el nombre; null no luce ninguno.
class SetActiveTitle implements UseCase<Unit, String?> {
  const SetActiveTitle(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String? titleId) =>
      _repository.setActiveTitle(titleId);
}
