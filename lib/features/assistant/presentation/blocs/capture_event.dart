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
