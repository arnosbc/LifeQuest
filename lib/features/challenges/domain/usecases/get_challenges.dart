import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/challenges/domain/entities/challenges_board.dart';
import 'package:proyecto_movil/features/challenges/domain/repositories/challenges_repository.dart';

/// Lee los desafíos del día, el del mes y la liga semanal.
class GetChallenges implements UseCase<ChallengesBoard, NoParams> {
  const GetChallenges(this._repository);

  final ChallengesRepository _repository;

  @override
  Future<Either<Failure, ChallengesBoard>> call(NoParams params) =>
      _repository.getChallenges();
}
