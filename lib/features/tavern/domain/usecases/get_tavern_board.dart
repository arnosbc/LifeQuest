import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Lee los NPCs, sus misiones y el límite de la Taverna.
class GetTavernBoard implements UseCase<TavernBoard, NoParams> {
  const GetTavernBoard(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, TavernBoard>> call(NoParams params) =>
      _repository.getBoard();
}
