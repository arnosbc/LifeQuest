part of 'rpgenie_bloc.dart';

sealed class RpgenieState extends Equatable {
  const RpgenieState();

  @override
  List<Object?> get props => [];
}

class RpgenieInitial extends RpgenieState {
  const RpgenieInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class RpgenieLoading extends RpgenieState {
  const RpgenieLoading();
}

class RpgenieSuccess extends RpgenieState {
  const RpgenieSuccess(
    this.board, {
    this.refreshing = false,
    this.busy = false,
    this.message,
  });

  final RpgenieBoard board;

  /// Refresco en curso (deslizar hacia abajo).
  final bool refreshing;

  /// Completando, apartando o recargando.
  final bool busy;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, busy, message];
}

/// La primera carga falló; no hay datos que mostrar.
class RpgenieFailure extends RpgenieState {
  const RpgenieFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
