import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Acepta una misión del NPC con el título que escribió el usuario.
class AcceptNpcMission implements UseCase<Unit, AcceptNpcMissionParams> {
  const AcceptNpcMission(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AcceptNpcMissionParams params) =>
      _repository.acceptMission(npcId: params.npcId, title: params.title);
}

class AcceptNpcMissionParams extends Equatable {
  const AcceptNpcMissionParams({required this.npcId, required this.title});

  final String npcId;
  final String title;

  @override
  List<Object?> get props => [npcId, title];
}
