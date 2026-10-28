part of 'vision_bloc.dart';

sealed class VisionState extends Equatable {
  const VisionState();

  @override
  List<Object?> get props => [];
}

class VisionInitial extends VisionState {
  const VisionInitial();
}

class VisionLoading extends VisionState {
  const VisionLoading();
}

class VisionSuccess extends VisionState {
  const VisionSuccess(
    this.board, {
    this.refreshing = false,
    this.busyKey,
    this.message,
  });

  final VisionBoard board;
  final bool refreshing;

  /// `save` al guardar el texto, o el id del vínculo que cambia.
  final String? busyKey;
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, busyKey, message];
}

class VisionFailure extends VisionState {
  const VisionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
