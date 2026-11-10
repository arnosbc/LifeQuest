import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';

/// Recursos (045): la memoria de una tarea, un proyecto o una meta. Lo usan
/// Tareas, Proyectos y metas, el Asistente y Foco, por eso vive en `core`.
enum ResourceKind { link, image, pdf, note }

enum ResourceTargetKind { task, project, goal }

class ResourceTarget extends Equatable {
  const ResourceTarget(this.kind, this.id);

  const ResourceTarget.task(this.id) : kind = ResourceTargetKind.task;

  final ResourceTargetKind kind;
  final String id;

  @override
  List<Object?> get props => [kind, id];
}

/// Recurso guardado.
class Resource extends Equatable {
  const Resource({
    required this.id,
    required this.kind,
    required this.title,
    this.url,
    this.path,
    this.note,
  });

  final String id;
  final ResourceKind kind;
  final String title;

  /// Enlace (kind link).
  final String? url;

  /// Ruta en Storage (foto o PDF).
  final String? path;
  final String? note;

  @override
  List<Object?> get props => [id, kind, title, url, path, note];
}

/// Lo que el usuario eligió y aún no está guardado (al crear o al adjuntar).
class ResourceDraft extends Equatable {
  const ResourceDraft._(
    this.kind,
    this.title, {
    this.url,
    this.localPath,
    this.size,
    this.note,
  });

  factory ResourceDraft.link(String url) {
    final uri = Uri.tryParse(url.trim());
    return ResourceDraft._(
      ResourceKind.link,
      uri?.host.isNotEmpty == true ? uri!.host : url.trim(),
      url: url.trim(),
    );
  }

  /// Foto o PDF del teléfono; [name] es el nombre del archivo.
  factory ResourceDraft.file({
    required String localPath,
    required String name,
    required int size,
  }) => ResourceDraft._(
    name.toLowerCase().endsWith('.pdf') ? ResourceKind.pdf : ResourceKind.image,
    name.length > 200 ? name.substring(0, 200) : name,
    localPath: localPath,
    size: size,
  );

  factory ResourceDraft.note(String text) =>
      ResourceDraft._(ResourceKind.note, 'Nota', note: text.trim());

  final ResourceKind kind;
  final String title;
  final String? url;
  final String? localPath;
  final int? size;
  final String? note;

  /// Tope del bucket (045).
  static const maxBytes = 10 * 1024 * 1024;

  bool get isFile => kind == ResourceKind.image || kind == ResourceKind.pdf;

  /// Extensión permitida por el bucket; null si no se puede subir.
  String? get extension {
    if (!isFile) return null;
    final ext = title.split('.').last.toLowerCase();
    const ok = {'jpg', 'jpeg', 'png', 'webp', 'pdf'};
    return ok.contains(ext) ? ext : null;
  }

  /// Motivo en español si no se puede guardar; null si está bien.
  String? get problem {
    if (kind == ResourceKind.link &&
        !RegExp(r'^https?://\S+$', caseSensitive: false).hasMatch(url ?? '')) {
      return 'El enlace debe empezar por http:// o https://.';
    }
    if (isFile && extension == null) return 'Solo fotos (JPG, PNG, WEBP) o PDF.';
    if (isFile && (size ?? 0) > maxBytes) return 'El archivo pasa de 10 MB.';
    if (kind == ResourceKind.note && (note ?? '').isEmpty) return 'La nota está vacía.';
    return null;
  }

  @override
  List<Object?> get props => [kind, title, url, localPath, size, note];
}

/// Lo que se manda a la IA: rutas de fotos y PDF ya subidos y texto de
/// notas y enlaces (Edge Function `assistant`, 045).
class AiContext extends Equatable {
  const AiContext({this.paths = const [], this.context = const []});

  /// De recursos ya guardados.
  factory AiContext.of(Iterable<Resource> resources) => AiContext(
    paths: [
      for (final r in resources)
        if (r.path != null) r.path!,
    ].take(3).toList(),
    context: [
      for (final r in resources)
        if (r.kind == ResourceKind.note) r.note!
        else if (r.kind == ResourceKind.link) '${r.title}: ${r.url}',
    ].take(5).toList(),
  );

  final List<String> paths;
  final List<String> context;

  bool get isEmpty => paths.isEmpty && context.isEmpty;

  @override
  List<Object?> get props => [paths, context];
}

abstract class ResourceRepository {
  Future<Either<Failure, List<Resource>>> list(ResourceTarget target);

  /// Sube el archivo si hace falta y guarda la fila.
  Future<Either<Failure, Unit>> attach(
    ResourceTarget target,
    ResourceDraft draft,
  );

  /// Borra la fila y, si tiene, su archivo.
  Future<Either<Failure, Unit>> delete(Resource resource);

  /// URL para abrir: el enlace o una firmada de 1 h para el archivo.
  Future<Either<Failure, String>> openUrl(Resource resource);

  /// Para la IA antes de que exista la tarea: sube los archivos (una sola
  /// vez; [attach] reutiliza la ruta) y arma el contexto.
  Future<Either<Failure, AiContext>> prepareForAi(List<ResourceDraft> drafts);
}
