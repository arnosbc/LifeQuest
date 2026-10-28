import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';

/// Lee los avisos; el parámetro es la hora local.
class GetNotifications implements UseCase<List<AppNotification>, DateTime> {
  const GetNotifications(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, List<AppNotification>>> call(DateTime params) =>
      _repository.getNotifications(params);
}
