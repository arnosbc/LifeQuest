import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Divide la tarea en foco: añade un paso que se marca durante la sesión.
class AddFocusStep implements UseCase<Unit, ({String taskId, String title})> {
  const AddFocusStep(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String taskId, String title}) params) {
    final title = params.title.trim();
    if (title.isEmpty || title.length > 200) {
      return Future.value(
        const Left(ServerFailure('Escribe un paso de hasta 200 caracteres.')),
      );
    }
    return _repository.addStep(taskId: params.taskId, title: title);
  }
}
