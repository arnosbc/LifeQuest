part of 'assistant_bloc.dart';

sealed class AssistantEvent extends Equatable {
  const AssistantEvent();

  @override
  List<Object?> get props => [];
}

/// Calcular la propuesta (armar el día o replanificar).
class AssistantPlanRequested extends AssistantEvent {
  const AssistantPlanRequested(this.mode);

  final PlanMode mode;

  @override
  List<Object?> get props => [mode];
}

/// El usuario acepta la propuesta tal cual.
class AssistantPlanAccepted extends AssistantEvent {
  const AssistantPlanAccepted();
}
