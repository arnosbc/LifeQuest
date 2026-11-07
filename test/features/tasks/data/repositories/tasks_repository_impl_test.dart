import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/tasks/data/models/tasks_board_model.dart';
import 'package:proyecto_movil/features/tasks/data/repositories/tasks_repository_impl.dart';

import '../../../../helpers/mocks.dart';
import '../../tasks_fixtures.dart';

void main() {
  late MockTasksRemoteDataSource remote;
  late TasksRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(newTask));

  setUp(() {
    remote = MockTasksRemoteDataSource();
    repository = TasksRepositoryImpl(remote);
  });

  test('getBoard devuelve la entidad', () async {
    when(
      () => remote.getBoard(),
    ).thenAnswer((_) async => const TasksBoardModel({}));
    expect(await repository.getBoard(), const Right(emptyBoard));
  });

  test('createTask pasa la tarea al datasource', () async {
    when(() => remote.createTask(any())).thenAnswer((_) async {});
    expect(await repository.createTask(newTask), const Right(unit));
    verify(() => remote.createTask(newTask)).called(1);
  });

  test('traduce los motivos del servidor a mensajes en español', () async {
    when(
      () => remote.completeTask('t1'),
    ).thenThrow(const ServerException(code: 'task_not_open'));
    expect(
      await repository.completeTask('t1'),
      const Left(ServerFailure('Esa tarea ya estaba cerrada. ¡Una menos!')),
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
