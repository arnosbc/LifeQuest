part of 'marketplace_bloc.dart';

sealed class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar el Marketplace.
class MarketplaceRequested extends MarketplaceEvent {
  const MarketplaceRequested();
}

/// Compra en el Hotel o el Mercado.
class MarketItemBought extends MarketplaceEvent {
  const MarketItemBought(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

/// Canje en el Mercado negro; [habitId] solo para "Recuperar racha".
class BlackMarketItemBought extends MarketplaceEvent {
  const BlackMarketItemBought(this.code, {this.habitId});

  final String code;
  final String? habitId;

  @override
  List<Object?> get props => [code, habitId];
}

/// Usar un Pase guardado sobre una racha rota.
class RecoveryPassUsed extends MarketplaceEvent {
  const RecoveryPassUsed(this.habitId);

  final String habitId;

  @override
  List<Object?> get props => [habitId];
}

class RefugeUpgraded extends MarketplaceEvent {
  const RefugeUpgraded(this.building);

  final String building;

  @override
  List<Object?> get props => [building];
}

class ElixirActivated extends MarketplaceEvent {
  const ElixirActivated();
}
