import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';

/// Lee el Perfil del Personaje.
class GetCharacterProfile implements UseCase<CharacterProfile, NoParams> {
  const GetCharacterProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, CharacterProfile>> call(NoParams params) =>
      _repository.getProfile();
}
