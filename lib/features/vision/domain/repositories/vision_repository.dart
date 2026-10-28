import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';

/// Contrato del Vision Board. La capa data lo implementa.
abstract class VisionRepository {
  Future<Either<Failure, VisionBoard>> getBoard();

  Future<Either<Failure, Unit>> save(String content);

  Future<Either<Failure, Unit>> setLink(
    VisionItem item, {
    required bool linked,
  });
}
