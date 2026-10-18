import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, CharacterProfile>> getProfile() =>
      _run(() async => (await _remote.getProfile()).toEntity());

  @override
  Future<Either<Failure, Unit>> updateIdentity({
    required String displayName,
    String? identityStatement,
  }) => _run(() async {
    await _remote.updateIdentity(
      displayName: displayName,
      identityStatement: identityStatement,
    );
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> createSkill(String name) => _run(() async {
    await _remote.createSkill(name);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> renameSkill({
    required String skillId,
    required String name,
  }) => _run(() async {
    await _remote.renameSkill(skillId: skillId, name: name);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> deleteSkill(String skillId) => _run(() async {
    await _remote.deleteSkill(skillId);
    return unit;
  });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error)));
    }
  }

  /// Mensajes que dicen qué hacer, con tono de invitación.
  static String _messageFor(ServerException error) =>
      switch ((error.code, error.statusCode)) {
        ('skill_limit_reached', _) =>
          'Ya tienes el máximo de skills. Libera una o amplía el límite en '
              'Game Master.',
        // FK de npcs.skill_id (ON DELETE RESTRICT).
        (_, '23503') =>
          'Un NPC de la Taverna usa esta skill. Asígnale otra antes de '
              'eliminarla.',
        // CHECK de longitud (002_profile.sql).
        (_, '23514') =>
          'Usa un nombre de 1 a 40 caracteres y una identidad de hasta 280.',
        ('profile_not_found', _) =>
          'Estamos preparando tu personaje. Desliza para actualizar en un '
              'momento.',
        _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
      };
}
