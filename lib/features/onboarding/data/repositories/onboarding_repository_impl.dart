import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._remote);

  final OnboardingRemoteDataSource _remote;

  @override
  Future<Either<Failure, OnboardingStatus>> getStatus() =>
      _run(() async => (await _remote.getStatus()).toEntity());

  @override
  Future<Either<Failure, Unit>> complete(OnboardingChoices choices) =>
      _run(() async {
        try {
          await _remote.complete(choices);
        } on ServerException catch (error) {
          // Ya lo había terminado (p. ej. en otro teléfono): no es un error.
          if (error.code != 'onboarding_done') rethrow;
        }
        return unit;
      });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'Sin conexión. Revisa tu internet y vuelve a intentarlo.',
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error)));
    }
  }

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(ServerException error) => switch (error.code) {
    'skill_exists' => 'Ya tienes una skill con ese nombre.',
    'skill_limit_reached' => 'Ya tienes el máximo de skills.',
    _ when error.statusCode == '23514' =>
      'Usa una identidad de hasta 280 caracteres y una skill de hasta 40.',
    _ => 'No pudimos guardar tu aventura. Inténtalo de nuevo.',
  };
}
