import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/home/data/datasources/home_remote_datasource.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<Either<Failure, HomeDashboard>> getDashboard(DateTime now) =>
      _run(() async {
        final model = await _remote.getDashboard(
          day: _day(now),
          utcOffsetMinutes: now.timeZoneOffset.inMinutes,
        );
        return model.toEntity();
      });

  @override
  Future<Either<Failure, Unit>> completeHabit({
    required String habitId,
    required DateTime now,
  }) => _run(() async {
    await _remote.completeHabit(habitId: habitId, day: _day(now));
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> claimDailyChest() => _run(() async {
    await _remote.claimDailyChest();
    return unit;
  });

  static String _day(DateTime now) =>
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

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
    'already_completed' => 'Ese hábito ya quedó registrado hoy. ¡Bien hecho!',
    'not_scheduled' => 'Este hábito no toca hoy. Te espera su próximo día.',
    'habit_not_found' => 'No encontramos ese hábito. Desliza para actualizar.',
    'invalid_day' =>
      'La fecha de tu teléfono no coincide con la de hoy. Revísala y reintenta.',
    'chest_already_claimed' => 'Ya abriste el cofre de hoy. Mañana habrá otro.',
    'chest_locked' => 'Cumple tus misiones del día para abrir el cofre.',
    'profile_not_found' =>
      'Estamos preparando tu personaje. Desliza para actualizar en un momento.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
