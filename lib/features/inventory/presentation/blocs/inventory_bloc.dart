import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/inventory/domain/entities/inventory_board.dart';
import 'package:proyecto_movil/features/inventory/domain/usecases/get_inventory.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({required this._getInventory})
    : super(const InventoryInitial()) {
    on<InventoryRequested>(_onRequested, transformer: droppable());
  }

  final GetInventory _getInventory;

  Future<void> _onRequested(
    InventoryRequested event,
    Emitter<InventoryState> emit,
  ) async {
    final current = state;
    emit(
      current is InventorySuccess
          ? InventorySuccess(current.board, refreshing: true)
          : const InventoryLoading(),
    );
    final result = await _getInventory(const NoParams());
    emit(
      result.match(
        (failure) => current is InventorySuccess
            ? InventorySuccess(current.board, message: failure.message)
            : InventoryFailure(failure.message),
        InventorySuccess.new,
      ),
    );
  }
}
