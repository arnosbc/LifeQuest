import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/documents/domain/entities/document_template.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';
import 'package:proyecto_movil/features/documents/domain/usecases/documents_usecases.dart';

class DocumentsState extends Equatable {
  const DocumentsState({
    this.documents = const [],
    this.loading = true,
    this.syncing = false,
    this.message,
  });

  final List<WorkDocument> documents;
  final bool loading;
  final bool syncing;

  /// Aviso puntual (sin conexión, error al borrar…).
  final String? message;

  DocumentsState copyWith({
    List<WorkDocument>? documents,
    bool? loading,
    bool? syncing,
    String? message,
  }) => DocumentsState(
    documents: documents ?? this.documents,
    loading: loading ?? this.loading,
    syncing: syncing ?? this.syncing,
    message: message,
  );

  @override
  List<Object?> get props => [documents, loading, syncing, message];
}

/// Lista del Taller: muestra al instante lo del teléfono y luego sincroniza.
class DocumentsCubit extends Cubit<DocumentsState> {
  DocumentsCubit({
    required this._getLocal,
    required this._sync,
    required this._create,
    required this._save,
    required this._delete,
  }) : super(const DocumentsState());

  final GetLocalDocuments _getLocal;
  final SyncDocuments _sync;
  final CreateDocument _create;
  final SaveDocument _save;
  final DeleteDocument _delete;

  Future<void> load() async {
    final local = await _getLocal(const NoParams());
    emit(
      local.match(
        (f) =>
            state.copyWith(loading: false, syncing: true, message: f.message),
        (docs) =>
            state.copyWith(documents: docs, loading: false, syncing: true),
      ),
    );
    final synced = await _sync(const NoParams());
    if (isClosed) return;
    emit(
      synced.match(
        (f) => state.copyWith(syncing: false, message: f.message),
        (docs) => state.copyWith(documents: docs, syncing: false),
      ),
    );
  }

  /// Devuelve el documento creado para abrirlo, o null si falló.
  Future<WorkDocument?> create(String title, DocumentTemplate template) async =>
      (await _create((title: title, template: template, taskId: null))).match(
        (f) {
          emit(state.copyWith(message: f.message));
          return null;
        },
        (doc) {
          emit(state.copyWith(documents: [doc, ...state.documents]));
          return doc;
        },
      );

  Future<void> rename(WorkDocument document, String title) async {
    final renamed = document.copyWith(
      title: title,
      updatedAt: DateTime.now().toUtc(),
    );
    (await _save(renamed)).match(
      (f) => emit(state.copyWith(message: f.message)),
      (doc) => emit(
        state.copyWith(
          documents: [
            for (final d in state.documents) d.id == doc.id ? doc : d,
          ],
        ),
      ),
    );
  }

  Future<void> delete(WorkDocument document) async {
    final before = state.documents;
    emit(
      state.copyWith(
        documents: [
          for (final d in before)
            if (d.id != document.id) d,
        ],
      ),
    );
    (await _delete(document)).match(
      (f) => emit(state.copyWith(documents: before, message: f.message)),
      (_) {},
    );
  }
}
