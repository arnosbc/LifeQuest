part of 'inventory_bloc.dart';

sealed class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

class InventorySuccess extends InventoryState {
  const InventorySuccess(this.board, {this.refreshing = false, this.message});

  final InventoryBoard board;
  final bool refreshing;

  /// Aviso puntual (un refresco que falló).
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, message];
}

class InventoryFailure extends InventoryState {
  const InventoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
