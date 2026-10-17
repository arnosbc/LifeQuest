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

/// No hubo conexión con el servidor.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
