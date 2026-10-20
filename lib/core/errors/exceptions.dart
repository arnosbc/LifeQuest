/// Errores que lanzan los datasources (capa data). Los repositorios los
/// capturan y los convierten en [Failure] de la capa domain.
library;

/// El servidor respondió con un error. [code] es el código de la API
/// (p. ej. `invalid_credentials`) cuando existe.
class ServerException implements Exception {
  const ServerException({this.code, this.message, this.statusCode});

  final String? code;
  final String? message;
  final String? statusCode;

  @override
  String toString() => 'ServerException($code, $statusCode): $message';
}

/// No se pudo llegar al servidor (sin conexión, tiempo agotado).
class NetworkException implements Exception {
  const NetworkException([this.message]);

  final String? message;

  @override
  String toString() => 'NetworkException: $message';
}

/// No se pudo leer o escribir el almacenamiento local del dispositivo.
class CacheException implements Exception {
  const CacheException([this.message]);

  final String? message;

  @override
  String toString() => 'CacheException: $message';
}
