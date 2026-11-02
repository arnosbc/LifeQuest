import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Left;

import 'package:proyecto_movil/features/guided_task/domain/entities/guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_evidence.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_review.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/complete_guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/get_guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/review_guided_step.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/set_guided_steps.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/toggle_guided_step.dart';

part 'guided_task_event.dart';
part 'guided_task_state.dart';

/// Tarea guiada paso a paso (plan B2). Lo ganado lo muestra el momento de
/// recompensa (RewardFeed); aquí solo se vuelve a leer la tarea.
class GuidedTaskBloc extends Bloc<GuidedTaskEvent, GuidedTaskState> {
  // Mantiene nombres públicos para get_it y dependencias privadas en el bloc.
  GuidedTaskBloc({
    required GetGuidedTask getTask,
    required ToggleGuidedStep toggleStep,
    required CompleteGuidedTask completeTask,
    required ReviewGuidedStep reviewStep,
    required SetGuidedSteps setSteps,
  }) : _getTask = getTask, // ignore: prefer_initializing_formals
       // ignore: prefer_initializing_formals
       _toggleStep = toggleStep,
       // ignore: prefer_initializing_formals
       _completeTask = completeTask,
       // ignore: prefer_initializing_formals
       _reviewStep = reviewStep,
       // ignore: prefer_initializing_formals
       _setSteps = setSteps,
       super(const GuidedTaskLoading()) {
    on<GuidedTaskRequested>(_onRequested, transformer: droppable());
    on<GuidedStepToggled>(_onStepToggled, transformer: droppable());
    on<GuidedTaskCompleted>(_onCompleted, transformer: droppable());
    on<GuidedStepReviewRequested>(_onReviewRequested, transformer: droppable());
    on<GuidedStepsSet>(_onStepsSet, transformer: droppable());
  }

  final GetGuidedTask _getTask;
  final ToggleGuidedStep _toggleStep;
  final CompleteGuidedTask _completeTask;
  final ReviewGuidedStep _reviewStep;
  final SetGuidedSteps _setSteps;

  Future<void> _onRequested(
    GuidedTaskRequested event,
    Emitter<GuidedTaskState> emit,
  ) async {
    final result = await _getTask(event.taskId);
    emit(
      result.match(
        (failure) => GuidedTaskFailure(failure.message),
        GuidedTaskSuccess.new,
      ),
    );
  }

  Future<void> _onStepToggled(
    GuidedStepToggled event,
    Emitter<GuidedTaskState> emit,
  ) async {
    final current = state;
    if (current is! GuidedTaskSuccess ||
        current.busy ||
        current.task.current?.id != event.stepId) {
      return;
    }
    emit(GuidedTaskSuccess(current.task, busyStepId: event.stepId));
    final toggled = await _toggleStep(event.stepId);
    if (toggled case Left(value: final failure)) {
      emit(GuidedTaskSuccess(current.task, message: failure.message));
      return;
    }
    await _reload(
      emit,
      current.task,
      toggled.getOrElse((_) => false) ? '¡Tarea completada!' : null,
    );
  }

  Future<void> _onCompleted(
    GuidedTaskCompleted event,
    Emitter<GuidedTaskState> emit,
  ) async {
    final current = state;
    if (current is! GuidedTaskSuccess || current.busy) return;
    emit(GuidedTaskSuccess(current.task, completing: true));
    final completed = await _completeTask(current.task.id);
    if (completed case Left(value: final failure)) {
      emit(GuidedTaskSuccess(current.task, message: failure.message));
      return;
    }
    await _reload(emit, current.task, '¡Tarea completada!');
  }

  Future<void> _onReviewRequested(
    GuidedStepReviewRequested event,
    Emitter<GuidedTaskState> emit,
  ) async {
    final current = state;
    if (current is! GuidedTaskSuccess ||
        current.busy ||
        current.task.current?.id != event.stepId ||
        current.task.completed) {
      return;
    }
    emit(GuidedTaskSuccess(current.task, reviewingStepId: event.stepId));
    final result = await _reviewStep(
      ReviewGuidedStepParams(stepId: event.stepId, evidence: event.evidence),
    );
    result.match(
      (failure) =>
          emit(GuidedTaskSuccess(current.task, message: failure.message)),
      (review) => emit(GuidedTaskSuccess(current.task, review: review)),
    );
  }

  Future<void> _onStepsSet(
    GuidedStepsSet event,
    Emitter<GuidedTaskState> emit,
  ) async {
    final current = state;
    if (current is! GuidedTaskSuccess || current.busy) return;
    emit(GuidedTaskSuccess(current.task, completing: true));
    final saved = await _setSteps(
      SetGuidedStepsParams(taskId: current.task.id, steps: event.steps),
    );
    if (saved case Left(value: final failure)) {
      emit(GuidedTaskSuccess(current.task, message: failure.message));
      return;
    }
    await _reload(emit, current.task, 'Pasos guardados. ¡A por el primero!');
  }

  Future<void> _reload(
    Emitter<GuidedTaskState> emit,
    GuidedTask previous,
    String? message,
  ) async {
    final reloaded = await _getTask(previous.id);
    emit(
      reloaded.match(
        (failure) => GuidedTaskSuccess(previous, message: failure.message),
        (task) => GuidedTaskSuccess(task, message: message),
      ),
    );
  }
}
