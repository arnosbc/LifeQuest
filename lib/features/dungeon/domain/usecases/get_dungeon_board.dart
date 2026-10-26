import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Lee la sesión abierta y las misiones para la mochila.
class GetDungeonBoard implements UseCase<DungeonBoard, NoParams> {
  const GetDungeonBoard(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, DungeonBoard>> call(NoParams params) =>
      _repository.getBoard();
}
