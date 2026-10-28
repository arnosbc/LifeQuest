import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/activate_elixir.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/buy_black_market_item.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/buy_market_item.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/get_market_board.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/upgrade_refuge.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/use_recovery_pass.dart';

part 'marketplace_event.dart';
part 'marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  MarketplaceBloc({
    required this._getBoard,
    required this._buyItem,
    required this._buyBlackMarket,
    required this._usePass,
    required this._upgradeRefuge,
    required this._activateElixir,
  }) : super(const MarketplaceInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<MarketplaceRequested>(_onRequested, transformer: droppable());
    on<MarketItemBought>(
      (e, emit) => _act(
        emit,
        e.code,
        () => _buyItem(e.code),
        '¡Disfrútalo! Te lo ganaste.',
      ),
      transformer: droppable(),
    );
    on<BlackMarketItemBought>(
      (e, emit) => _act(
        emit,
        e.code,
        () => _buyBlackMarket(BlackMarketParams(e.code, habitId: e.habitId)),
        e.habitId == null ? 'Pase guardado.' : '¡Racha salvada! Sigue así.',
      ),
      transformer: droppable(),
    );
    on<RecoveryPassUsed>(
      (e, emit) => _act(
        emit,
        e.habitId,
        () => _usePass(e.habitId),
        '¡Racha salvada! Sigue así.',
      ),
      transformer: droppable(),
    );
    on<RefugeUpgraded>(
      (e, emit) => _act(
        emit,
        e.building,
        () => _upgradeRefuge(e.building),
        'Tu Refugio creció.',
      ),
      transformer: droppable(),
    );
    on<ElixirActivated>(
      (e, emit) => _act(
        emit,
        'elixir_activate',
        () => _activateElixir(const NoParams()),
        'Elixir activo: tu próxima Mazmorra dará ×1,5 de XP.',
      ),
      transformer: droppable(),
    );
  }

  final GetMarketBoard _getBoard;
  final BuyMarketItem _buyItem;
  final BuyBlackMarketItem _buyBlackMarket;
  final UseRecoveryPass _usePass;
  final UpgradeRefuge _upgradeRefuge;
  final ActivateElixir _activateElixir;

  Future<void> _onRequested(
    MarketplaceRequested event,
    Emitter<MarketplaceState> emit,
  ) async {
    final current = state;
    emit(
      current is MarketplaceSuccess
          ? MarketplaceSuccess(current.board, refreshing: true)
          : const MarketplaceLoading(),
    );
    final result = await _getBoard(const NoParams());
    emit(
      result.match(
        (failure) => current is MarketplaceSuccess
            ? MarketplaceSuccess(current.board, message: failure.message)
            : MarketplaceFailure(failure.message),
        MarketplaceSuccess.new,
      ),
    );
  }

  /// Marca [busyKey], ejecuta [action] y, si sale bien, vuelve a leer:
  /// Monedas, vida y límites los calcula el servidor.
  Future<void> _act(
    Emitter<MarketplaceState> emit,
    String busyKey,
    Future<Either<Failure, Unit>> Function() action,
    String message,
  ) async {
    final current = state;
    if (current is! MarketplaceSuccess) return;
    emit(MarketplaceSuccess(current.board, busyKey: busyKey));
    if (await action() case Left(value: final failure)) {
      emit(MarketplaceSuccess(current.board, message: failure.message));
      return;
    }
    final reloaded = await _getBoard(const NoParams());
    emit(
      reloaded.match(
        (failure) =>
            MarketplaceSuccess(current.board, message: failure.message),
        (board) => MarketplaceSuccess(board, message: message),
      ),
    );
  }
}
