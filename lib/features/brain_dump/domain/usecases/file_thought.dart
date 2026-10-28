import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';

/// Guarda una idea no accionable en Algún día o Referencia, o la devuelve a
/// la bandeja.
class FileThought implements UseCase<Unit, FileThoughtParams> {
  const FileThought(this._repository);

  final BrainDumpRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(FileThoughtParams params) =>
      _repository.file(params.thoughtId, params.shelf);
}

class FileThoughtParams extends Equatable {
  const FileThoughtParams(this.thoughtId, this.shelf);

  final String thoughtId;
  final ThoughtShelf shelf;

  @override
  List<Object?> get props => [thoughtId, shelf];
}
