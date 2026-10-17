import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';

/// Caso de uso con una sola responsabilidad, invocable con `call()`.
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// Parámetros vacíos para casos de uso que no reciben datos.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
