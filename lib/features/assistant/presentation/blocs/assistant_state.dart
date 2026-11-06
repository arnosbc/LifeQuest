part of 'assistant_bloc.dart';

sealed class AssistantState extends Equatable {
  const AssistantState();

  @override
  List<Object?> get props => [];
}

class AssistantInitial extends AssistantState {
  const AssistantInitial();
}

class AssistantLoading extends AssistantState {
  const AssistantLoading();
}

/// Propuesta lista para revisar.
class AssistantProposal extends AssistantState {
  const AssistantProposal(this.plan, {this.saving = false, this.message});

  final DayPlan plan;
  final bool saving;

  /// Error al aceptar; la propuesta sigue en pantalla.
  final String? message;

  @override
  List<Object?> get props => [plan, saving, message];
}

/// Propuesta aceptada: [count] bloques quedaron en la agenda.
class AssistantApplied extends AssistantState {
  const AssistantApplied(this.count);

  final int count;

  @override
  List<Object?> get props => [count];
}

class AssistantFailure extends AssistantState {
  const AssistantFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
