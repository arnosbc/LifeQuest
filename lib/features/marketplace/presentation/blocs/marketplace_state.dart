part of 'marketplace_bloc.dart';

sealed class MarketplaceState extends Equatable {
  const MarketplaceState();

  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class MarketplaceSuccess extends MarketplaceState {
  const MarketplaceSuccess(
    this.board, {
    this.refreshing = false,
    this.busyKey,
    this.message,
  });

  final MarketBoard board;
  final bool refreshing;

  /// Código del ítem, hábito o mejora que se está procesando.
  final String? busyKey;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, busyKey, message];
}

/// La primera carga falló; no hay datos que mostrar.
class MarketplaceFailure extends MarketplaceState {
  const MarketplaceFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
