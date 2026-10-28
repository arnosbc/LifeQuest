import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/domain/repositories/brain_dump_repository.dart';

/// Borra una idea; el parámetro es su id.
class DeleteThought implements UseCase<Unit, String> {
  const DeleteThought(this._repository);

  final BrainDumpRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      _repository.delete(params);
}
