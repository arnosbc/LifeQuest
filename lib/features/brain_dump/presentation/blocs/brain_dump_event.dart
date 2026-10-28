part of 'brain_dump_bloc.dart';

sealed class BrainDumpEvent extends Equatable {
  const BrainDumpEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar el Brain Dump.
class BrainDumpRequested extends BrainDumpEvent {
  const BrainDumpRequested();
}

class ThoughtCaptured extends BrainDumpEvent {
  const ThoughtCaptured(this.content);

  final String content;

  @override
  List<Object?> get props => [content];
}

class ThoughtFiled extends BrainDumpEvent {
  const ThoughtFiled(this.thoughtId, this.shelf);

  final String thoughtId;
  final ThoughtShelf shelf;

  @override
  List<Object?> get props => [thoughtId, shelf];
}

class ThoughtConverted extends BrainDumpEvent {
  const ThoughtConverted(this.conversion);

  final Conversion conversion;

  @override
  List<Object?> get props => [conversion];
}

class ThoughtDeleted extends BrainDumpEvent {
  const ThoughtDeleted(this.thoughtId);

  final String thoughtId;

  @override
  List<Object?> get props => [thoughtId];
}
