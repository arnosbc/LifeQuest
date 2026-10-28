import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/rpgenie/domain/entities/current_mission.dart';
import 'package:proyecto_movil/features/rpgenie/domain/repositories/rpgenie_repository.dart';

/// Pide la Misión actual; el parámetro son los ids apartados con "Ahora no".
class GetCurrentMission implements UseCase<RpgenieBoard, List<String>> {
  const GetCurrentMission(this._repository);

  final RpgenieRepository _repository;

  @override
  Future<Either<Failure, RpgenieBoard>> call(List<String> params) =>
      _repository.getCurrentMission(params);
}
