import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/challenges/data/datasources/challenges_remote_datasource.dart';
import 'package:proyecto_movil/features/challenges/domain/entities/challenges_board.dart';
import 'package:proyecto_movil/features/challenges/domain/repositories/challenges_repository.dart';

class ChallengesRepositoryImpl implements ChallengesRepository {
  const ChallengesRepositoryImpl(this._remote);

  final ChallengesRemoteDataSource _remote;

  @override
  Future<Either<Failure, ChallengesBoard>> getChallenges() =>
      _run(() async => (await _remote.getChallenges()).toEntity());

  @override
  Future<Either<Failure, Unit>> claimChallenge(String key) => _run(() async {
    await _remote.claimChallenge(key);
    return unit;
  });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error.code)));
    }
  }

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(String? code) => switch (code) {
    'challenge_already_claimed' => 'Ese cofre ya es tuyo. ¡Bien hecho!',
    'challenge_locked' => 'Aún te falta un poco para abrir este cofre.',
    'challenge_not_found' =>
      'No encontramos ese desafío. Desliza para actualizar.',
    _ => 'No pudimos abrir tus Desafíos. Inténtalo en un momento.',
  };
}
