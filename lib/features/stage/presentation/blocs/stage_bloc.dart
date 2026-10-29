import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/archive_stage_item.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/complete_stage_task.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_goal.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_project.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_resource.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/get_resource_url.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/get_stage_board.dart';

part 'stage_event.dart';
part 'stage_state.dart';

class StageBloc extends Bloc<StageEvent, StageState> {
  StageBloc({
    required this._getStageBoard,
    required this._createProject,
    required this._createGoal,
    required this._completeTask,
    required this._createResource,
    required this._resourceUrl,
    required this._archive,
    required this._completeProject,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const StageInitial()) {
    // droppable: toques repetidos mientras trabaja se ignoran.
    on<StageRequested>(_onRequested, transformer: droppable());
    on<StageProjectCreated>(
      (event, emit) => _act(
        emit,
        () => _createProject(event.project),
        'Proyecto creado. Añádele misiones para avanzar.',
      ),
      transformer: droppable(),
    );
    on<StageGoalCreated>(
      (event, emit) => _act(
        emit,
        () => _createGoal(event.goal),
        '¡Nueva meta! Un jefe aparece en el horizonte.',
      ),
      transformer: droppable(),
    );
    on<StageTaskCompleted>(
      (event, emit) => _act(
        emit,
        () => _completeTask(event.taskId),
        '¡Misión completada! Tu héroe se hace más fuerte.',
      ),
      transformer: droppable(),
    );
    on<StageResourceCreated>(
      (event, emit) => _act(
        emit,
        () => _createResource(event.resource),
        switch (event.resource.kind) {
          ResourceKind.link => 'Enlace guardado en tus Recursos.',
          ResourceKind.note => 'Nota guardada en tus Recursos.',
          ResourceKind.document => 'Documento guardado en tus Recursos.',
        },
      ),
      transformer: droppable(),
    );
    on<StageResourceOpened>(_onResourceOpened, transformer: droppable());
    on<StageItemArchived>(
      (event, emit) => _act(
        emit,
        () => _archive(ArchiveStageItemParams(kind: event.kind, id: event.id)),
        'Enviado al Archivo.',
      ),
      transformer: droppable(),
    );
    on<StageProjectCompleted>(
      (event, emit) => _act(
        emit,
        () => _completeProject(event.projectId),
        '¡Proyecto completado! Tu héroe se hace más fuerte.',
      ),
      transformer: droppable(),
    );
  }

  final GetStageBoard _getStageBoard;
  final CreateProject _createProject;
  final CreateGoal _createGoal;
  final CompleteStageTask _completeTask;
  final CreateResource _createResource;
  final GetResourceUrl _resourceUrl;
  final ArchiveStageItem _archive;
  final CompleteProject _completeProject;
  final DateTime Function() _clock;

  Future<void> _onRequested(
    StageRequested event,
    Emitter<StageState> emit,
  ) async {
    final current = state;
    emit(
      current is StageSuccess
          ? StageSuccess(current.board, refreshing: true)
          : const StageLoading(),
    );
    final result = await _getStageBoard(_clock());
    emit(
      result.match(
        (failure) => current is StageSuccess
            ? StageSuccess(current.board, message: failure.message)
            : StageFailure(failure.message),
        StageSuccess.new,
      ),
    );
  }

  /// Pide el enlace temporal del documento; la pantalla lo abre al ver
  /// [StageSuccess.openUrl].
  Future<void> _onResourceOpened(
    StageResourceOpened event,
    Emitter<StageState> emit,
  ) async {
    final current = state;
    if (current is! StageSuccess || current.busy) return;
    emit(StageSuccess(current.board, busy: true));
    final result = await _resourceUrl(event.resource);
    emit(
      result.match(
        (failure) => StageSuccess(current.board, message: failure.message),
        (url) => StageSuccess(current.board, openUrl: url),
      ),
    );
  }

  /// Ejecuta [action] y, si sale bien, vuelve a leer: progreso, urgencia y
  /// recompensas los calcula el servidor.
  Future<void> _act(
    Emitter<StageState> emit,
    Future<Either<Failure, Unit>> Function() action,
    String message,
  ) async {
    final current = state;
    if (current is! StageSuccess || current.busy) return;
    emit(StageSuccess(current.board, busy: true));
    if (await action() case Left(value: final failure)) {
      emit(StageSuccess(current.board, message: failure.message));
      return;
    }
    final reloaded = await _getStageBoard(_clock());
    emit(
      reloaded.match(
        (failure) => StageSuccess(current.board, message: failure.message),
        (board) => StageSuccess(board, message: message),
      ),
    );
  }
}
