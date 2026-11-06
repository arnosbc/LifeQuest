import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

/// Acepta la propuesta: cada bloque queda en la agenda.
class ApplyDayPlan implements UseCase<Unit, List<ProposedBlock>> {
  const ApplyDayPlan(this._repository);

  final AssistantRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<ProposedBlock> blocks) =>
      _repository.applyBlocks(blocks);
}
