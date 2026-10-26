import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/domain/repositories/dungeon_repository.dart';

/// Cierra la sesión por su id y devuelve el resumen.
class EndDungeon implements UseCase<DungeonSummary, String> {
  const EndDungeon(this._repository);

  final DungeonRepository _repository;

  @override
  Future<Either<Failure, DungeonSummary>> call(String params) =>
      _repository.end(params);
}
