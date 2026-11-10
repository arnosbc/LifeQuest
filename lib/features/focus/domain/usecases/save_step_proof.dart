import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';

/// Prueba de un paso hecho: una nota o una foto como recurso del paso (045).
class SaveStepProof
    implements UseCase<Unit, ({String stepId, ResourceDraft proof})> {
  const SaveStepProof(this._resources);

  final ResourceRepository _resources;

  @override
  Future<Either<Failure, Unit>> call(
    ({String stepId, ResourceDraft proof}) p,
  ) => _resources.attach(ResourceTarget.task(p.stepId), p.proof);
}
