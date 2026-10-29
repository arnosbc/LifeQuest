import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// RPGenie propone la misión de un NPC (título y guía); null si no pudo.
class SuggestNpcMission implements UseCase<NpcMissionSuggestion?, String> {
  const SuggestNpcMission(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, NpcMissionSuggestion?>> call(String npcId) =>
      _repository.suggestMission(npcId);
}
