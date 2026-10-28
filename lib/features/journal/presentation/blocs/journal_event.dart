part of 'journal_bloc.dart';

sealed class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar el Diario.
class JournalRequested extends JournalEvent {
  const JournalRequested();
}
