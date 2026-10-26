import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/habits/data/datasources/habits_remote_datasource.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/features/habits/domain/repositories/habits_repository.dart';

class HabitsRepositoryImpl implements HabitsRepository {
  const HabitsRepositoryImpl(this._remote);

  final HabitsRemoteDataSource _remote;

  @override
  Future<Either<Failure, HabitsBoard>> getBoard(DateTime now) =>
      _run(() async => (await _remote.getBoard(_day(now))).toEntity());

  @override
  Future<Either<Failure, Unit>> createHabit(NewHabit habit) => _run(() async {
    await _remote.createHabit(habit);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> completeGoodHabit({
    required String habitId,
    required DateTime now,
  }) => _run(() async {
    await _remote.completeGoodHabit(habitId: habitId, day: _day(now));
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> registerBadHabit(String habitId) =>
      _run(() async {
        await _remote.registerBadHabit(habitId);
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
    'invalid_name' => 'Dale a tu hábito un nombre de hasta 100 caracteres.',
    'invalid_severity' => 'Elige qué tanto te afecta: leve, media o grave.',
    'invalid_days' => 'Elige al menos un día de la semana.',
    'skill_not_found' =>
      'Esa skill ya no está disponible. Elige otra o deja el hábito sin vincular.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
