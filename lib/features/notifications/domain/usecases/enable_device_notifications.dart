import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';

/// Activa los avisos en el dispositivo; el parámetro se llama al tocar uno.
class EnableDeviceNotifications implements UseCase<Unit, void Function()> {
  const EnableDeviceNotifications(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(void Function() params) =>
      _repository.enableOnDevice(params);
}
