import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Lee la sesión abierta y las tareas para la mochila.
class GetFocusBoard implements UseCase<FocusBoard, NoParams> {
  const GetFocusBoard(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, FocusBoard>> call(NoParams params) =>
      _repository.getBoard();
}
