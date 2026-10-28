part of 'journal_bloc.dart';

sealed class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {
  const JournalInitial();
}

class JournalLoading extends JournalState {
  const JournalLoading();
}

class JournalSuccess extends JournalState {
  const JournalSuccess(this.board, {this.refreshing = false, this.message});

  final JournalBoard board;
  final bool refreshing;

  /// Aviso puntual (un refresco que falló).
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, message];
}

class JournalFailure extends JournalState {
  const JournalFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
