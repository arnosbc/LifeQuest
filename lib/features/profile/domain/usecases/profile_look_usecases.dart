import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_look_repository.dart';

/// Lee la apariencia del Perfil; la de fábrica si nunca se eligió.
class GetProfileLook implements UseCase<ProfileLook, NoParams> {
  const GetProfileLook(this._repository);

  final ProfileLookRepository _repository;

  @override
  Future<Either<Failure, ProfileLook>> call(NoParams params) =>
      _repository.getLook();
}

class SaveProfileLook implements UseCase<Unit, ProfileLook> {
  const SaveProfileLook(this._repository);

  final ProfileLookRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ProfileLook look) =>
      _repository.saveLook(look);
}

/// Copia la foto del avatar o el fondo elegido (ruta de la galería) y
/// devuelve la ruta de la copia.
class ImportProfileMedia implements UseCase<String, ProfileMediaParams> {
  const ImportProfileMedia(this._repository);

  final ProfileLookRepository _repository;

  @override
  Future<Either<Failure, String>> call(ProfileMediaParams params) =>
      _repository.importMedia(params.sourcePath, kind: params.kind.name);
}

enum ProfileMediaKind { avatar, backdrop }

typedef ProfileMediaParams = ({String sourcePath, ProfileMediaKind kind});
