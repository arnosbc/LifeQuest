part of 'brain_dump_bloc.dart';

sealed class BrainDumpState extends Equatable {
  const BrainDumpState();

  @override
  List<Object?> get props => [];
}

class BrainDumpInitial extends BrainDumpState {
  const BrainDumpInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class BrainDumpLoading extends BrainDumpState {
  const BrainDumpLoading();
}

/// Datos listos. Las acciones posteriores no los quitan de la pantalla.
class BrainDumpSuccess extends BrainDumpState {
  const BrainDumpSuccess(
    this.board, {
    this.refreshing = false,
    this.busyKey,
    this.message,
  });

  final BrainDumpBoard board;
  final bool refreshing;

  /// Idea que se está procesando, o `capture` al guardar una nueva.
  final String? busyKey;

  /// Aviso puntual para mostrar en un snackbar.
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, busyKey, message];
}

/// La primera carga falló; no hay datos que mostrar.
class BrainDumpFailure extends BrainDumpState {
  const BrainDumpFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
