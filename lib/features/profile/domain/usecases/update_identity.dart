import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';

/// Guarda el nombre del héroe y su respuesta a «¿Quién eres en este reino?».
class UpdateIdentity implements UseCase<Unit, UpdateIdentityParams> {
  const UpdateIdentity(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdateIdentityParams params) =>
      _repository.updateIdentity(
        displayName: params.displayName,
        identityStatement: params.identityStatement,
      );
}

class UpdateIdentityParams extends Equatable {
  const UpdateIdentityParams({
    required this.displayName,
    this.identityStatement,
  });

  final String displayName;
  final String? identityStatement;

  @override
  List<Object?> get props => [displayName, identityStatement];
}
