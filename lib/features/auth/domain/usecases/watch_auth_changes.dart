import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/domain/repositories/auth_repository.dart';

/// Avisa cada vez que se inicia o se cierra la sesión (null), también cuando
/// la sesión llega desde fuera de la app, como al volver de Google o Apple.
class WatchAuthChanges {
  const WatchAuthChanges(this._repository);

  final AuthRepository _repository;

  Stream<User?> call() => _repository.authChanges();
}
