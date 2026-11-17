import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';

/// Apariencia del Perfil guardada en el dispositivo.
abstract interface class ProfileLookRepository {
  /// La de fábrica si nunca se guardó.
  Future<Either<Failure, ProfileLook>> getLook();

  Future<Either<Failure, Unit>> saveLook(ProfileLook look);

  /// Guarda una copia del archivo ('avatar' o 'backdrop') y devuelve su ruta.
  Future<Either<Failure, String>> importMedia(
    String sourcePath, {
    required String kind,
  });
}
