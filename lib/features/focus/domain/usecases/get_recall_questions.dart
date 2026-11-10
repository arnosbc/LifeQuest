import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/focus/domain/entities/focus_board.dart';
import 'package:proyecto_movil/features/focus/domain/repositories/focus_repository.dart';

/// Repaso activo: preguntas sobre lo que el usuario anotó la última vez.
/// Sin notas no hay nada que repasar (y no se gasta la IA).
class GetRecallQuestions implements UseCase<List<String>, FocusTask> {
  const GetRecallQuestions(this._repository);

  final FocusRepository _repository;

  @override
  Future<Either<Failure, List<String>>> call(FocusTask task) {
    final notes = task.recallNotes;
    if (notes.isEmpty) {
      return Future.value(
        const Left(ServerFailure('Aún no hay notas que repasar.')),
      );
    }
    return _repository.recallQuestions(title: task.title, notes: notes);
  }
}
