import 'package:equatable/equatable.dart';

/// Error de la capa domain con un mensaje listo para mostrar al usuario.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// El servidor rechazó la operación (credenciales, datos inválidos…).
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Los datos no cumplen las reglas antes de enviarlos (tipo, tamaño…).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// No hubo conexión con el servidor.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Falló el almacenamiento local del dispositivo.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
