import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_local_datasource.dart';
import 'package:proyecto_movil/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';
import 'package:proyecto_movil/features/reminders/domain/repositories/reminders_repository.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  const RemindersRepositoryImpl(this._remote, this._local);

  final RemindersRemoteDataSource _remote;
  final RemindersLocalDataSource _local;

  @override
  Future<Either<Failure, ReminderPlan>> getPlan() async {
    try {
      final zone = await _local.timeZone();
      return Right((await _remote.sync(zone)).toEntity());
    } on CacheException {
      return const Left(
        CacheFailure('No pudimos leer la zona horaria del teléfono.'),
      );
    } on NetworkException {
      return const Left(
        NetworkFailure('Sin conexión: los avisos se actualizan al volver.'),
      );
    } on ServerException {
      return const Left(ServerFailure('No pudimos traer tus avisos.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> replaceAll(
    List<LocalReminder> reminders,
  ) async {
    try {
      await _local.replaceAll(reminders);
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure('No pudimos programar los avisos.'));
    }
  }
}
