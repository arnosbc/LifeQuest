import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';

/// Contrato del centro de avisos. La capa data lo implementa.
abstract class NotificationsRepository {
  /// [now] es la hora local: define qué avisos de "hoy" se generan.
  Future<Either<Failure, List<AppNotification>>> getNotifications(DateTime now);

  /// Marca leídos los avisos de [ids]; si es null, todos.
  Future<Either<Failure, Unit>> markRead(List<String>? ids);
}
