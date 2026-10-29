import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';

/// Apaga los avisos en el dispositivo (al cerrar sesión).
class DisableDeviceNotifications implements UseCase<Unit, NoParams> {
  const DisableDeviceNotifications(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.disableOnDevice();
}
