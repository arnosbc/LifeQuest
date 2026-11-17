import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/challenges/domain/entities/challenges_board.dart';

/// Contrato de Desafíos y Liga. La capa data lo implementa.
abstract class ChallengesRepository {
  Future<Either<Failure, ChallengesBoard>> getChallenges();

  /// [key]: `xp`, `tasks`, `focus` o `month`.
  Future<Either<Failure, Unit>> claimChallenge(String key);
}
