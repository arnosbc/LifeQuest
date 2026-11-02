import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';
import 'package:proyecto_movil/features/marketplace/domain/repositories/marketplace_repository.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this._remote);

  final MarketplaceRemoteDataSource _remote;

  @override
  Future<Either<Failure, MarketBoard>> getBoard() =>
      _run(() async => (await _remote.getBoard()).toEntity());

  @override
  Future<Either<Failure, Unit>> buyItem(String code) =>
      _done(() => _remote.purchase(code));

  @override
  Future<Either<Failure, Unit>> buyBlackMarketItem(
    String code, {
    String? habitId,
  }) => _done(() => _remote.buyBlackMarket(code, habitId));

  @override
  Future<Either<Failure, Unit>> useRecoveryPass(String habitId) =>
      _done(() => _remote.useRecoveryPass(habitId));

  @override
  Future<Either<Failure, Unit>> upgradeRefuge(String building) =>
      _done(() => _remote.upgradeRefuge(building));

  @override
  Future<Either<Failure, Unit>> activateElixir() =>
      _done(_remote.activateElixir);

  Future<Either<Failure, Unit>> _done(Future<void> Function() action) =>
      _run(() async {
        await action();
        return unit;
      });

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'No hay conexión con el servidor. Revisa tu internet y reintenta.',
        ),
      );
    } on ServerException catch (error) {
      return Left(ServerFailure(_messageFor(error.code)));
    }
  }

  /// Motivos que lanzan las funciones SQL, en tono de invitación.
  static String _messageFor(String? code) => switch (code) {
    'not_enough_coins' =>
      'Aún te faltan Monedas. Cada tarea te acerca a esta recompensa.',
    'daily_limit_reached' => 'Ya lo compraste hoy. Vuelve mañana por otro.',
    'active_limit_reached' =>
      'Ya tienes una bonificación guardada para tu próxima sesión de Modo Foco.',
    'monthly_limit_reached' =>
      'Ya lo usaste este mes. Podrás volver a usarlo el próximo mes.',
    'too_many_passes' =>
      'Ya tienes el máximo de protectores de racha guardados.',
    'nothing_to_recover' =>
      'Esa racha ya no se puede reparar, pero tu récord sigue guardado.',
    'no_pass' =>
      'No tienes protectores de racha guardados. Puedes conseguir uno en Recompensas.',
    'habit_required' => 'Elige qué racha quieres reparar.',
    'max_level' => 'Esta mejora ya está al nivel máximo. ¡Buen trabajo!',
    'elixir_already_active' =>
      'Ya tienes una bonificación activa para tu próxima sesión de Modo Foco.',
    'no_elixir' => 'No tienes bonificaciones guardadas.',
    'item_not_found' || 'item_not_available' =>
      'Ese ítem ya no está disponible. Desliza para actualizar.',
    'habit_not_found' => 'No encontramos ese hábito. Desliza para actualizar.',
    _ => 'Algo salió mal. Inténtalo de nuevo en un momento.',
  };
}
