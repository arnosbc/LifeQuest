import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';
import 'package:proyecto_movil/features/vision/domain/repositories/vision_repository.dart';

/// Vincula o desvincula una Meta o un Proyecto de la visión.
class SetVisionLink implements UseCase<Unit, VisionLinkParams> {
  const SetVisionLink(this._repository);

  final VisionRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(VisionLinkParams params) =>
      _repository.setLink(params.item, linked: params.linked);
}

class VisionLinkParams extends Equatable {
  const VisionLinkParams(this.item, {required this.linked});

  final VisionItem item;
  final bool linked;

  @override
  List<Object?> get props => [item, linked];
}
