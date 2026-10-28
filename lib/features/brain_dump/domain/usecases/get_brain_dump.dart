import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';

/// Lee la bandeja, Algún día y Referencia.
class GetBrainDump implements UseCase<BrainDumpBoard, NoParams> {
  const GetBrainDump(this._repository);

  final BrainDumpRepository _repository;

  @override
  Future<Either<Failure, BrainDumpBoard>> call(NoParams params) =>
      _repository.getBoard();
}
