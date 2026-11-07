import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Cierra la sesión por su id y devuelve el resumen.
class EndFocus implements UseCase<FocusSummary, String> {
  const EndFocus(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, FocusSummary>> call(String params) =>
      _repository.end(params);
}
