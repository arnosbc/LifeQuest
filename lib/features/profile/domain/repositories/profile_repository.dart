import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

/// Contrato del Perfil del Personaje. La capa data lo implementa.
abstract class ProfileRepository {
  Future<Either<Failure, CharacterProfile>> getProfile();

  /// [identityStatement] vacío o null borra la identidad.
  Future<Either<Failure, Unit>> updateIdentity({
    required String displayName,
    String? identityStatement,
  });

  Future<Either<Failure, Unit>> createSkill(String name);

  Future<Either<Failure, Unit>> renameSkill({
    required String skillId,
    required String name,
  });

  /// La skill se quita de metas, proyectos, tareas y hábitos que la usen.
  Future<Either<Failure, Unit>> deleteSkill(String skillId);
}
