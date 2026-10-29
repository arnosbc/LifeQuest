import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// RPGenie propone el título de la misión de un NPC; null si no pudo.
class SuggestNpcMission implements UseCase<String?, String> {
  const SuggestNpcMission(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, String?>> call(String npcId) =>
      _repository.suggestMission(npcId);
}
