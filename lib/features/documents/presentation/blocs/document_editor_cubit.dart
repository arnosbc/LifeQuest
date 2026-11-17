import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/documents/domain/entities/document_template.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';
import 'package:proyecto_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:proyecto_movil/features/documents/domain/usecases/documents_usecases.dart';

enum SaveStatus { saved, pending, failed }

class DocumentEditorState extends Equatable {
  const DocumentEditorState({
    this.document,
    this.status = SaveStatus.saved,
    this.exporting = false,
    this.message,
    this.notFound = false,
    this.revision = 0,
  });

  /// Sube al restaurar una versión: la pantalla recarga el texto.
  final int revision;

  /// Null mientras se abre.
  final WorkDocument? document;
  final SaveStatus status;
  final bool exporting;
  final String? message;
  final bool notFound;

  DocumentEditorState copyWith({
    WorkDocument? document,
    SaveStatus? status,
    bool? exporting,
    String? message,
    bool? notFound,
    int? revision,
  }) => DocumentEditorState(
    document: document ?? this.document,
    status: status ?? this.status,
    exporting: exporting ?? this.exporting,
    message: message,
    notFound: notFound ?? this.notFound,
    revision: revision ?? this.revision,
  );

  @override
  List<Object?> get props => [
    document,
    status,
    exporting,
    message,
    notFound,
    revision,
  ];
}

/// Un documento abierto: guarda solo, medio segundo después de dejar de
/// escribir, y al cerrar.
class DocumentEditorCubit extends Cubit<DocumentEditorState> {
  DocumentEditorCubit({
    required this._getLocal,
    required this._create,
    required this._save,
    required this._export,
    required this._snapshot,
    required this._versions,
    required this._addImage,
    required this._resolveImage,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const DocumentEditorState());

  final GetLocalDocuments _getLocal;
  final CreateDocument _create;
  final SaveDocument _save;
  final ExportDocument _export;
  final SnapshotDocument _snapshot;
  final GetDocumentVersions _versions;
  final AddDocumentImage _addImage;
  final ResolveDocumentImage _resolveImage;

  // Rutas ya resueltas: la vista previa no vuelve a buscar cada imagen.
  final _imagePaths = <String, String?>{};
  final DateTime Function() _clock;

  static const debounce = Duration(milliseconds: 600);
  Timer? _timer;

  /// Por [id], o el de la tarea [taskId] (si no existe, se crea con [title]).
  Future<void> open({String? id, String? taskId, String? title}) async {
    final docs = (await _getLocal(const NoParams())).getOrElse((_) => const []);
    WorkDocument? found;
    for (final d in docs) {
      if ((id != null && d.id == id) ||
          (taskId != null && d.taskId == taskId)) {
        found = d;
        break;
      }
    }
    if (found == null && taskId != null) {
      found = (await _create((
        title: title ?? 'Trabajo de la tarea',
        template: DocumentTemplate.blank,
        taskId: taskId,
      ))).toNullable();
    }
    if (isClosed) return;
    // Copia de cómo estaba al abrirlo, para poder volver atrás.
    if (found != null) await _snapshot(found);
    if (isClosed) return;
    emit(
      found == null
          ? state.copyWith(notFound: true)
          : state.copyWith(document: found),
    );
  }

  void edit({String? content, String? title}) {
    final doc = state.document;
    if (doc == null) return;
    emit(
      state.copyWith(
        document: doc.copyWith(
          content: content,
          title: title,
          updatedAt: _clock().toUtc(),
        ),
        status: SaveStatus.pending,
      ),
    );
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  /// Guarda ya lo pendiente (al salir de la pantalla, antes de exportar).
  Future<void> flush() async {
    _timer?.cancel();
    final doc = state.document;
    if (doc == null || state.status == SaveStatus.saved) return;
    final result = await _save(doc);
    if (isClosed) return;
    // Si se siguió escribiendo mientras guardaba, queda pendiente.
    if (state.document != doc) return;
    emit(
      result.match(
        (f) => state.copyWith(status: SaveStatus.failed, message: f.message),
        (_) => state.copyWith(status: SaveStatus.saved),
      ),
    );
  }

  /// Ruta del archivo listo para compartir, o null si falló.
  Future<String?> export(ExportFormat format) async {
    final doc = state.document;
    if (doc == null) return null;
    await flush();
    emit(state.copyWith(exporting: true));
    final result = await _export((document: doc, format: format));
    if (isClosed) return null;
    return result.match(
      (f) {
        emit(state.copyWith(exporting: false, message: f.message));
        return null;
      },
      (path) {
        emit(state.copyWith(exporting: false));
        return path;
      },
    );
  }

  /// Agrega la imagen elegida; devuelve el texto Markdown para insertarla.
  Future<String?> addImage(String sourcePath) async {
    final doc = state.document;
    if (doc == null) return null;
    final result = await _addImage((documentId: doc.id, path: sourcePath));
    if (isClosed) return null;
    return result.match((f) {
      emit(state.copyWith(message: f.message));
      return null;
    }, (name) => '![Imagen](img/$name)');
  }

  /// Ruta en el teléfono de una imagen del documento (la baja si falta).
  Future<String?> resolveImage(String name) async {
    final doc = state.document;
    if (doc == null) return null;
    if (_imagePaths.containsKey(name)) return _imagePaths[name];
    final path = (await _resolveImage((
      documentId: doc.id,
      path: name,
    ))).getOrElse((_) => null);
    if (path != null) _imagePaths[name] = path;
    return path;
  }

  /// Historial del documento abierto.
  Future<List<WorkDocument>> versions() async {
    final doc = state.document;
    if (doc == null) return const [];
    return (await _versions(doc.id)).getOrElse((_) => const []);
  }

  /// Vuelve a [version]. Antes guarda en el historial cómo está ahora.
  Future<void> restore(WorkDocument version) async {
    final doc = state.document;
    if (doc == null) return;
    await flush();
    await _snapshot(state.document!);
    if (isClosed) return;
    emit(
      state.copyWith(
        document: doc.copyWith(
          content: version.content,
          title: version.title,
          updatedAt: _clock().toUtc(),
        ),
        status: SaveStatus.pending,
        revision: state.revision + 1,
      ),
    );
    await flush();
  }

  @override
  Future<void> close() async {
    await flush();
    if (state.document case final doc?) await _snapshot(doc);
    return super.close();
  }
}
