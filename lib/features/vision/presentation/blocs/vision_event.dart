part of 'vision_bloc.dart';

sealed class VisionEvent extends Equatable {
  const VisionEvent();

  @override
  List<Object?> get props => [];
}

class VisionRequested extends VisionEvent {
  const VisionRequested();
}

class VisionSaved extends VisionEvent {
  const VisionSaved(this.content);

  final String content;

  @override
  List<Object?> get props => [content];
}

class VisionLinkToggled extends VisionEvent {
  const VisionLinkToggled(this.item, {required this.linked});

  final VisionItem item;
  final bool linked;

  @override
  List<Object?> get props => [item, linked];
}
