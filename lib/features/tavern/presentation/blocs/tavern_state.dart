part of 'tavern_bloc.dart';

sealed class TavernState extends Equatable {
  const TavernState();

  @override
  List<Object?> get props => [];
}

class TavernInitial extends TavernState {
  const TavernInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class TavernLoading extends TavernState {
  const TavernLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class TavernSuccess extends TavernState {
  const TavernSuccess(
    this.board, {
    this.refreshing = false,
    this.busyKey,
    this.message,
  });

  final TavernBoard board;
  final bool refreshing;

  /// NPC que se está procesando, o `new_npc` al crear uno.
  final String? busyKey;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, busyKey, message];
}

/// La primera carga falló; no hay datos que mostrar.
class TavernFailure extends TavernState {
  const TavernFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
