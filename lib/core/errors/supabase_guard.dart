import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';

/// Capa data: convierte los errores del SDK de Supabase en [ServerException]
/// o [NetworkException]. Las funciones SQL lanzan su motivo como mensaje
/// (p. ej. `task_not_open`), que pasa a [ServerException.code]; las Edge
/// Functions lo devuelven en `{"error": …}`.
Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on ServerException {
    rethrow;
  } on PostgrestException catch (error) {
    // En debug, el motivo real a la consola: la UI solo muestra un mensaje genérico.
    if (kDebugMode) debugPrint('Supabase ${error.code}: ${error.message}');
    throw ServerException(
      code: error.message,
      message: error.details?.toString(),
      statusCode: error.code,
    );
  } on FunctionException catch (error) {
    final details = error.details;
    throw ServerException(
      code: details is Map ? details['error']?.toString() : null,
      statusCode: '${error.status}',
    );
  } on ClientException catch (error) {
    throw NetworkException(error.message);
  } on TimeoutException catch (error) {
    throw NetworkException(error.message);
  }
}

const networkFailureMessage =
    'No hay conexión con el servidor. Revisa tu internet y reintenta.';

/// Capa data → domain: el resultado o un [Failure] con un mensaje en
/// español. [serverMessage] traduce el motivo del servidor; cada feature
/// tiene los suyos.
Future<Either<Failure, T>> runGuarded<T>(
  Future<T> Function() action,
  String Function(ServerException error) serverMessage, {
  String network = networkFailureMessage,
}) async {
  try {
    return Right(await action());
  } on NetworkException {
    return Left(NetworkFailure(network));
  } on ServerException catch (error) {
    return Left(ServerFailure(serverMessage(error)));
  } catch (error, stack) {
    // JSON inesperado o plugin que falla: sin esto el bloc se queda cargando.
    // H-05: el log de release lo lee cualquiera con adb; solo en debug.
    if (kDebugMode) debugPrint('Error inesperado: $error\n$stack');
    return Left(ServerFailure(serverMessage(const ServerException())));
  }
}
