import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/missions/domain/entities/missions_board.dart';
import 'package:proyecto_movil/features/missions/domain/repositories/missions_repository.dart';

/// Lee las misiones abiertas y las opciones para vincular.
class GetMissionsBoard implements UseCase<MissionsBoard, NoParams> {
  const GetMissionsBoard(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, MissionsBoard>> call(NoParams params) =>
      _repository.getBoard();
}
