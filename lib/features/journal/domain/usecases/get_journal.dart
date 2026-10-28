import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';
import 'package:proyecto_movil/features/journal/domain/repositories/journal_repository.dart';

/// Lee la Bitácora y su resumen semanal; el parámetro es la hora local.
class GetJournal implements UseCase<JournalBoard, DateTime> {
  const GetJournal(this._repository);

  final JournalRepository _repository;

  @override
  Future<Either<Failure, JournalBoard>> call(DateTime params) =>
      _repository.getJournal(params);
}
