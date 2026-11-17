import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/data/datasources/profile_look_local_datasource.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_look_repository.dart';

class ProfileLookRepositoryImpl implements ProfileLookRepository {
  const ProfileLookRepositoryImpl(this._local);

  final ProfileLookLocalDataSource _local;

  @override
  Future<Either<Failure, ProfileLook>> getLook() async {
    try {
      return Right(await _local.getLook() ?? const ProfileLook());
    } on CacheException {
      return const Left(CacheFailure('No pudimos leer cómo se ve tu perfil.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveLook(ProfileLook look) async {
    try {
      await _local.saveLook(look);
      return const Right(unit);
    } on CacheException {
      return const Left(
        CacheFailure('No pudimos guardar el cambio. Inténtalo de nuevo.'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> importMedia(
    String sourcePath, {
    required String kind,
  }) async {
    try {
      return Right(await _local.importMedia(sourcePath, kind: kind));
    } on CacheException {
      return const Left(CacheFailure('No pudimos guardar el archivo.'));
    }
  }
}
