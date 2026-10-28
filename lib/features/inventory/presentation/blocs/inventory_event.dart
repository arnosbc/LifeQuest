part of 'inventory_bloc.dart';

sealed class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar el Inventario.
class InventoryRequested extends InventoryEvent {
  const InventoryRequested();
}
