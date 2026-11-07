part of 'capture_bloc.dart';

sealed class CaptureState extends Equatable {
  const CaptureState();

  @override
  List<Object?> get props => [];
}

/// Campo de texto; [busy] mientras se interpreta, [listening] mientras se
/// dicta ([heard] es lo reconocido hasta ahora).
class CaptureWriting extends CaptureState {
  const CaptureWriting({
    this.busy = false,
    this.listening = false,
    this.heard,
    this.message,
  });

  final bool busy;
  final bool listening;
  final String? heard;
  final String? message;

  @override
  List<Object?> get props => [busy, listening, heard, message];
}

class CapturePreview extends CaptureState {
  const CapturePreview({
    required this.draft,
    required this.usedAi,
    required this.aiAvailable,
    this.kind = CaptureKind.task,
    this.smart,
    this.steps = const [],
    this.busy = false,
    this.message,
  });

  final CaptureKind kind;

  /// Solo en metas: lo que propuso la IA.
  final SmartGoal? smart;
  final TaskDraft draft;
  final bool usedAi;
  final bool aiAvailable;
  final List<DraftStep> steps;
  final bool busy;

  /// Aviso puntual (IA caída, error al guardar…).
  final String? message;

  CapturePreview copy({
    TaskDraft? draft,
    List<DraftStep>? steps,
    bool busy = false,
    String? message,
  }) => CapturePreview(
    draft: draft ?? this.draft,
    usedAi: usedAi,
    aiAvailable: aiAvailable,
    kind: kind,
    smart: smart,
    steps: steps ?? this.steps,
    busy: busy,
    message: message,
  );

  @override
  List<Object?> get props => [
    kind,
    smart,
    draft,
    usedAi,
    aiAvailable,
    steps,
    busy,
    message,
  ];
}

/// Guardado; la hoja se cierra.
class CaptureSaved extends CaptureState {
  const CaptureSaved({required this.toInbox});

  final bool toInbox;

  @override
  List<Object?> get props => [toInbox];
}
