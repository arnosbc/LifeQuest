import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';

/// Contrato del centro de avisos. La capa data lo implementa.
abstract class NotificationsRepository {
  /// [now] es la hora local: define qué avisos de "hoy" se generan.
  Future<Either<Failure, List<AppNotification>>> getNotifications(DateTime now);

  /// Marca leídos los avisos de [ids]; si es null, todos.
  Future<Either<Failure, Unit>> markRead(List<String>? ids);

  /// Activa los avisos en este dispositivo: pide permiso, lo registra y
  /// programa la revisión periódica. [onOpened] se llama al tocar un aviso.
  Future<Either<Failure, Unit>> enableOnDevice(void Function() onOpened);

  /// Detiene la revisión periódica y da de baja el dispositivo.
  Future<Either<Failure, Unit>> disableOnDevice();

  /// Trae lo que toca mostrar ahora ([now] es la hora local) y lo muestra
  /// como notificación del sistema. Devuelve cuántas mostró.
  Future<Either<Failure, int>> deliverToDevice(DateTime now);
}
