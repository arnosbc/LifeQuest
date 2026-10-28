import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

/// Renombra un hábito.
class RenameHabit implements UseCase<Unit, RenameParams> {
  const RenameHabit(this._repository);

  final HabitsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RenameParams params) =>
      _repository.renameHabit(params.id, params.name);
}

/// Id y nombre nuevo.
class RenameParams extends Equatable {
  const RenameParams(this.id, this.name);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
