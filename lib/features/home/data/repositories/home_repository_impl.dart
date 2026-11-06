import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/calendar/phone_event.dart';
import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/home/data/datasources/home_remote_datasource.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remote, this._calendar);

  final HomeRemoteDataSource _remote;
  final PhoneCalendar _calendar;

  @override
  Future<Either<Failure, HomeDashboard>> getDashboard(DateTime now) =>
      _run(() async {
        final model = await _remote.getDashboard(
          day: _day(now),
          utcOffsetMinutes: now.timeZoneOffset.inMinutes,
        );
        final start = DateTime(now.year, now.month, now.day);
        final (access, events) = await (
          _calendar.access(),
          _calendar.events(start, start.add(const Duration(days: 1))),
        ).wait;
        return model.toEntity().withCalendar(access, events);
      });

  @override
  Future<Either<Failure, Unit>> connectCalendar() async {
    await _calendar.requestAccess();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> completeHabit({
    required String habitId,
    required DateTime now,
  }) => _run(() async {
    await _remote.completeHabit(habitId: habitId, day: _day(now));
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> scheduleTask({
    required String taskId,
    required DateTime? at,
  }) => _run(() async {
    await _remote.scheduleTask(taskId: taskId, at: at);
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
    'task_not_found' =>
      'Esa tarea ya no está abierta. Desliza para actualizar.',
    'invalid_day' =>
      'La fecha de tu teléfono no coincide con la de hoy. Revísala y reintenta.',
    'profile_not_found' =>
      'Estamos preparando tu cuenta. Desliza para actualizar en un momento.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
