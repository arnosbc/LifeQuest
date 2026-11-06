import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/apply_day_plan.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/get_day_plan.dart';

part 'assistant_event.dart';
part 'assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  AssistantBloc({required this._getDayPlan, required this._applyDayPlan})
    : super(const AssistantInitial()) {
    on<AssistantPlanRequested>(_onRequested, transformer: droppable());
    on<AssistantPlanAccepted>(_onAccepted, transformer: droppable());
  }

  final GetDayPlan _getDayPlan;
  final ApplyDayPlan _applyDayPlan;

  Future<void> _onRequested(
    AssistantPlanRequested event,
    Emitter<AssistantState> emit,
  ) async {
    emit(const AssistantLoading());
    final result = await _getDayPlan(event.mode);
    emit(
      result.match(
        (failure) => AssistantFailure(failure.message),
        AssistantProposal.new,
      ),
    );
  }

  Future<void> _onAccepted(
    AssistantPlanAccepted event,
    Emitter<AssistantState> emit,
  ) async {
    final current = state;
    if (current is! AssistantProposal || current.saving) return;
    emit(AssistantProposal(current.plan, saving: true));
    final result = await _applyDayPlan(current.plan.blocks);
    emit(
      result.match(
        (failure) => AssistantProposal(current.plan, message: failure.message),
        (_) => AssistantApplied(current.plan.blocks.length),
      ),
    );
  }
}
