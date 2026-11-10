import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// «Dónde lo dejé»: una línea que la próxima sesión muestra arriba.
class SaveResumeNote implements UseCase<Unit, ({String taskId, String note})> {
  const SaveResumeNote(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(({String taskId, String note}) p) {
    final note = p.note.trim();
    if (note.length > 500) {
      return Future.value(
        const Left(ServerFailure('La nota puede tener hasta 500 caracteres.')),
      );
    }
    return _repository.setResumeNote(taskId: p.taskId, note: note);
  }
}
