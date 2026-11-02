import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/documents/data/models/work_document_model.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';

/// Documentos en el teléfono: un archivo JSON por documento. Funciona sin red.
/// Lanza [CacheException].
abstract interface class DocumentsLocalDataSource {
  /// Todos, también los marcados como borrados (para sincronizar el borrado).
  Future<List<WorkDocument>> readAll();

  Future<void> write(WorkDocument document);

  /// Carpeta temporal donde se dejan los archivos exportados.
  Future<Directory> exportDir();

  /// Guarda una copia del documento en su historial (máx. [keep] copias).
  Future<void> addVersion(WorkDocument document, {int keep = 30});

  /// Copias del historial, de la más reciente a la más antigua.
  Future<List<WorkDocument>> versions(String documentId);

  /// Copia una imagen al documento y devuelve su nombre de archivo.
  Future<String> addImage(String documentId, String sourcePath);

  /// La imagen en el teléfono, o null si no está.
  Future<File?> imageFile(String documentId, String name);

  /// Guarda una imagen bajada de la nube (ya subida: no se vuelve a subir).
  Future<File> saveImage(String documentId, String name, List<int> bytes);

  /// Imágenes que aún no llegaron a la nube: (documento, nombre, archivo).
  Future<List<(String, String, File)>> pendingImages();

  Future<void> markUploaded(String documentId, String name);
}

class DocumentsLocalDataSourceImpl implements DocumentsLocalDataSource {
  DocumentsLocalDataSourceImpl({Future<Directory> Function()? root})
    : _root = root ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _root;

  Future<Directory> _dir() async {
    final dir = Directory('${(await _root()).path}/documents');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw CacheException('$error');
    }
  }

  @override
  Future<List<WorkDocument>> readAll() => _guard(() async {
    final files = (await _dir()).listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    );
    final docs = <WorkDocument>[];
    for (final file in files) {
      try {
        docs.add(
          WorkDocumentModel.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          ),
        );
      } on FormatException {
        // Un archivo dañado no debe esconder los demás documentos.
      }
    }
    return docs;
  });

  @override
  Future<void> write(WorkDocument document) => _guard(() async {
    final dir = await _dir();
    // Se escribe aparte y se renombra: un corte a mitad no daña el original.
    final tmp = File('${dir.path}/${document.id}.json.tmp');
    await tmp.writeAsString(jsonEncode(WorkDocumentModel.toJson(document)));
    await tmp.rename('${dir.path}/${document.id}.json');
  });

  Future<Directory> _versionsDir(String id) async {
    final dir = Directory('${(await _dir()).path}/versions/$id');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<void> addVersion(WorkDocument document, {int keep = 30}) =>
      _guard(() async {
        final dir = await _versionsDir(document.id);
        await File(
          '${dir.path}/${document.updatedAt.millisecondsSinceEpoch}.json',
        ).writeAsString(jsonEncode(WorkDocumentModel.toJson(document)));
        final files = dir.listSync().whereType<File>().toList()
          ..sort((a, b) => b.path.compareTo(a.path));
        for (final old in files.skip(keep)) {
          old.deleteSync();
        }
      });

  @override
  Future<List<WorkDocument>> versions(String documentId) => _guard(() async {
    final files = (await _versionsDir(
      documentId,
    )).listSync().whereType<File>().toList();
    final out = <WorkDocument>[];
    for (final f in files) {
      try {
        out.add(
          WorkDocumentModel.fromJson(
            jsonDecode(await f.readAsString()) as Map<String, dynamic>,
          ),
        );
      } on FormatException {
        // Una copia dañada no esconde las demás.
      }
    }
    return out..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  });

  Future<Directory> _imagesDir(String id) async {
    final dir = Directory('${(await _dir()).path}/images/$id');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<String> addImage(
    String documentId,
    String sourcePath,
  ) => _guard(() async {
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot < 0 ? 'jpg' : sourcePath.substring(dot + 1).toLowerCase();
    final name = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(sourcePath).copy('${(await _imagesDir(documentId)).path}/$name');
    return name;
  });

  @override
  Future<File?> imageFile(String documentId, String name) => _guard(() async {
    final file = File('${(await _imagesDir(documentId)).path}/$name');
    return file.existsSync() ? file : null;
  });

  @override
  Future<File> saveImage(String documentId, String name, List<int> bytes) =>
      _guard(() async {
        final dir = await _imagesDir(documentId);
        final file = await File('${dir.path}/$name').writeAsBytes(bytes);
        await File('${dir.path}/$name.up').create();
        return file;
      });

  @override
  Future<List<(String, String, File)>> pendingImages() => _guard(() async {
    final root = Directory('${(await _dir()).path}/images');
    if (!root.existsSync()) return const [];
    final out = <(String, String, File)>[];
    for (final dir in root.listSync().whereType<Directory>()) {
      final docId = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.endsWith('.up')) continue;
        if (!File('${f.path}.up').existsSync()) out.add((docId, name, f));
      }
    }
    return out;
  });

  @override
  Future<void> markUploaded(String documentId, String name) => _guard(
    () async =>
        File('${(await _imagesDir(documentId)).path}/$name.up').create(),
  );

  @override
  Future<Directory> exportDir() => _guard(() async {
    final dir = Directory('${(await _root()).path}/exports');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  });
}
