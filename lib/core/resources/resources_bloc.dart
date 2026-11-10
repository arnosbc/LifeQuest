import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/resources/resource.dart';

sealed class ResourcesEvent extends Equatable {
  const ResourcesEvent();

  @override
  List<Object?> get props => [];
}

class ResourcesRequested extends ResourcesEvent {
  const ResourcesRequested();
}

class ResourceAdded extends ResourcesEvent {
  const ResourceAdded(this.draft);

  final ResourceDraft draft;

  @override
  List<Object?> get props => [draft];
}

/// Se oculta ya y se borra al cerrar la ventana de deshacer.
class ResourceRemoved extends ResourcesEvent {
  const ResourceRemoved(this.resource);

  final Resource resource;

  @override
  List<Object?> get props => [resource];
}

class ResourceRemoveUndone extends ResourcesEvent {
  const ResourceRemoveUndone();
}

class ResourceOpened extends ResourcesEvent {
  const ResourceOpened(this.resource);

  final Resource resource;

  @override
  List<Object?> get props => [resource];
}

class _RemoveCommitted extends ResourcesEvent {
  const _RemoveCommitted();
}

class ResourcesState extends Equatable {
  const ResourcesState({
    this.loading = true,
    this.busy = false,
    this.items = const [],
    this.removing,
    this.error,
    this.toOpen,
  });

  final bool loading;

  /// Subiendo o guardando.
  final bool busy;
  final List<Resource> items;

  /// Oculto, esperando a que pase la ventana de deshacer.
  final Resource? removing;

  /// Error en línea dentro de la hoja.
  final String? error;

  /// URL lista para abrir (una vez).
  final String? toOpen;

  List<Resource> get visible =>
      [for (final r in items) if (r.id != removing?.id) r];

  ResourcesState copyWith({
    bool? loading,
    bool? busy,
    List<Resource>? items,
    Resource? Function()? removing,
    String? error,
    String? toOpen,
  }) => ResourcesState(
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    items: items ?? this.items,
    removing: removing == null ? this.removing : removing(),
    error: error,
    toOpen: toOpen,
  );

  @override
  List<Object?> get props => [loading, busy, items, removing, error, toOpen];
}

/// Hoja de recursos de una tarea, proyecto o meta.
class ResourcesBloc extends Bloc<ResourcesEvent, ResourcesState> {
  ResourcesBloc(
    this._repository,
    this.target, {
    this.undoWindow = const Duration(seconds: 5),
  }) : super(const ResourcesState()) {
    on<ResourcesRequested>(_onRequested, transformer: droppable());
    on<ResourceAdded>(_onAdded, transformer: sequential());
    on<ResourceRemoved>(_onRemoved);
    on<ResourceRemoveUndone>(_onUndone);
    on<_RemoveCommitted>(_onCommitted);
    on<ResourceOpened>(_onOpened, transformer: droppable());
  }

  final ResourceRepository _repository;
  final ResourceTarget target;
  final Duration undoWindow;
  Timer? _timer;

  Future<void> _onRequested(
    ResourcesRequested event,
    Emitter<ResourcesState> emit,
  ) async {
    final result = await _repository.list(target);
    emit(
      result.match(
        (f) => state.copyWith(loading: false, error: f.message),
        (items) => state.copyWith(loading: false, items: items),
      ),
    );
  }

  Future<void> _onAdded(
    ResourceAdded event,
    Emitter<ResourcesState> emit,
  ) async {
    if (event.draft.problem case final p?) return emit(state.copyWith(error: p));
    emit(state.copyWith(busy: true));
    final saved = await _repository.attach(target, event.draft);
    if (saved.getLeft().toNullable() case final f?) {
      return emit(state.copyWith(busy: false, error: f.message));
    }
    final list = await _repository.list(target);
    emit(state.copyWith(busy: false, items: list.getOrElse((_) => state.items)));
  }

  Future<void> _onRemoved(
    ResourceRemoved event,
    Emitter<ResourcesState> emit,
  ) async {
    await _flush(emit);
    emit(state.copyWith(removing: () => event.resource));
    _timer = Timer(undoWindow, () => add(const _RemoveCommitted()));
  }

  void _onUndone(ResourceRemoveUndone event, Emitter<ResourcesState> emit) {
    _timer?.cancel();
    emit(state.copyWith(removing: () => null));
  }

  Future<void> _onCommitted(
    _RemoveCommitted event,
    Emitter<ResourcesState> emit,
  ) => _flush(emit);

  /// Borra en el servidor lo que estaba esperando.
  Future<void> _flush(Emitter<ResourcesState> emit) async {
    _timer?.cancel();
    final r = state.removing;
    if (r == null) return;
    final result = await _repository.delete(r);
    emit(
      result.match(
        (f) => state.copyWith(removing: () => null, error: f.message),
        (_) => state.copyWith(
          removing: () => null,
          items: [for (final x in state.items) if (x.id != r.id) x],
        ),
      ),
    );
  }

  Future<void> _onOpened(
    ResourceOpened event,
    Emitter<ResourcesState> emit,
  ) async {
    final url = await _repository.openUrl(event.resource);
    emit(url.match((f) => state.copyWith(error: f.message), (u) => state.copyWith(toOpen: u)));
  }

  /// Al cerrar la hoja, lo pendiente se borra igual (no se pierde el gesto).
  @override
  Future<void> close() async {
    _timer?.cancel();
    if (state.removing case final r?) await _repository.delete(r);
    return super.close();
  }
}
