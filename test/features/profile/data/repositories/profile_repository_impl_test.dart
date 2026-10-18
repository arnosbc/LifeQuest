import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/profile/data/models/character_profile_model.dart';
import 'package:proyecto_movil/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

import '../../../../helpers/mocks.dart';
import '../../profile_fixtures.dart';

void main() {
  late MockProfileRemoteDataSource remote;
  late ProfileRepositoryImpl repository;

  setUp(() {
    remote = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(remote);
  });

  test('getProfile devuelve la entidad del modelo', () async {
    when(
      () => remote.getProfile(),
    ).thenAnswer((_) async => CharacterProfileModel.fromJson(profileJson));

    expect(
      await repository.getProfile(),
      const Right<Failure, CharacterProfile>(profile),
    );
  });

  test('updateIdentity pasa nombre e identidad', () async {
    when(
      () => remote.updateIdentity(displayName: 'Ana', identityStatement: 'Yo'),
    ).thenAnswer((_) async {});

    expect(
      await repository.updateIdentity(
        displayName: 'Ana',
        identityStatement: 'Yo',
      ),
      const Right<Failure, Unit>(unit),
    );
  });

  test('sin conexión devuelve NetworkFailure', () async {
    when(() => remote.createSkill(any())).thenThrow(const NetworkException());

    expect(
      await repository.createSkill('Salud'),
      const Left<Failure, Unit>(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      ),
    );
  });

  final cases = {
    const ServerException(code: 'skill_limit_reached', statusCode: 'P0001'):
        'Ya tienes el máximo de skills. Libera una o amplía el límite en '
        'Game Master.',
    const ServerException(code: 'update or delete…', statusCode: '23503'):
        'Un NPC de la Taverna usa esta skill. Asígnale otra antes de '
        'eliminarla.',
    const ServerException(code: 'new row violates…', statusCode: '23514'):
        'Usa un nombre de 1 a 40 caracteres y una identidad de hasta 280.',
    const ServerException(code: 'otra cosa'):
        'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
  for (final MapEntry(key: error, value: message) in cases.entries) {
    test('${error.code} (${error.statusCode}) se explica al usuario', () async {
      when(() => remote.deleteSkill(any())).thenThrow(error);

      expect(
        await repository.deleteSkill('s1'),
        Left<Failure, Unit>(ServerFailure(message)),
      );
    });
  }
}
