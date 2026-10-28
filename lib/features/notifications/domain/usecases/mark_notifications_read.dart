import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/notifications/domain/repositories/notifications_repository.dart';

/// Marca avisos como leídos; null marca todos.
class MarkNotificationsRead implements UseCase<Unit, List<String>?> {
  const MarkNotificationsRead(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(List<String>? params) =>
      _repository.markRead(params);
}
