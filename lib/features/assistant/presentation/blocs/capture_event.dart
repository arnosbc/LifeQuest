part of 'capture_bloc.dart';

sealed class CaptureEvent extends Equatable {
  const CaptureEvent();

  @override
  List<Object?> get props => [];
}

/// Interpretar lo que el usuario escribió.
class CaptureSubmitted extends CaptureEvent {
  const CaptureSubmitted(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Cambió qué se crea (tarea, proyecto o meta).
class CaptureKindChanged extends CaptureEvent {
  const CaptureKindChanged(this.kind);

  final CaptureKind kind;

  @override
  List<Object?> get props => [kind];
}

/// Empezar a dictar.
class CaptureListenRequested extends CaptureEvent {
  const CaptureListenRequested();
}

/// Dejar de dictar (lo oído hasta ahí se interpreta).
class CaptureListenStopped extends CaptureEvent {
  const CaptureListenStopped();
}

/// Quitó o cambió un chip de la vista previa.
class CaptureDraftEdited extends CaptureEvent {
  const CaptureDraftEdited(this.draft);

  final TaskDraft draft;

  @override
  List<Object?> get props => [draft];
}

/// Pedir a la IA que la divida en pasos.
class CaptureBreakdownRequested extends CaptureEvent {
  const CaptureBreakdownRequested();
}

/// Adjuntó un recurso en la vista previa.
class CaptureAttachmentAdded extends CaptureEvent {
  const CaptureAttachmentAdded(this.draft);

  final ResourceDraft draft;

  @override
  List<Object?> get props => [draft];
}

class CaptureAttachmentRemoved extends CaptureEvent {
  const CaptureAttachmentRemoved(this.draft);

  final ResourceDraft draft;

  @override
  List<Object?> get props => [draft];
}

/// Guardar como tarea o, con [toInbox], en la Bandeja.
class CaptureConfirmed extends CaptureEvent {
  const CaptureConfirmed({this.toInbox = false});

  final bool toInbox;

  @override
  List<Object?> get props => [toInbox];
}

/// Volver a escribir.
class CaptureRestarted extends CaptureEvent {
  const CaptureRestarted();
}
