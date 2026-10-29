import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';

/// Muestra en el dispositivo los avisos que tocan ahora; el parámetro es la
/// hora local. Lo usa la revisión en segundo plano.
class DeliverDeviceNotifications implements UseCase<int, DateTime> {
  const DeliverDeviceNotifications(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, int>> call(DateTime params) =>
      _repository.deliverToDevice(params);
}
