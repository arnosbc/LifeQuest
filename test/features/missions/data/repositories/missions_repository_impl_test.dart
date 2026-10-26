import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/missions/data/models/missions_board_model.dart';
import 'package:proyecto_movil/features/missions/data/repositories/missions_repository_impl.dart';

import '../../../../helpers/mocks.dart';
import '../../missions_fixtures.dart';

void main() {
  late MockMissionsRemoteDataSource remote;
  late MissionsRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(newMission));

  setUp(() {
    remote = MockMissionsRemoteDataSource();
    repository = MissionsRepositoryImpl(remote);
  });

  test('getBoard devuelve la entidad', () async {
    when(
      () => remote.getBoard(),
    ).thenAnswer((_) async => const MissionsBoardModel({}));
    expect(await repository.getBoard(), const Right(emptyBoard));
  });

  test('createMission pasa la misión al datasource', () async {
    when(() => remote.createMission(any())).thenAnswer((_) async {});
    expect(await repository.createMission(newMission), const Right(unit));
    verify(() => remote.createMission(newMission)).called(1);
  });

  test('traduce los motivos del servidor a mensajes en español', () async {
    when(
      () => remote.completeMission('t1'),
    ).thenThrow(const ServerException(code: 'task_not_open'));
    expect(
      await repository.completeMission('t1'),
      const Left(ServerFailure('Esa misión ya estaba cerrada. ¡Una menos!')),
    );
  });

  test('sin conexión devuelve NetworkFailure', () async {
    when(() => remote.getBoard()).thenThrow(const NetworkException());
    expect(
      (await repository.getBoard()).getLeft().toNullable(),
      isA<NetworkFailure>(),
    );
  });
}
