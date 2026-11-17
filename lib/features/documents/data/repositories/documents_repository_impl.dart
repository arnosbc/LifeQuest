import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:fpdart/fpdart.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/documents/data/datasources/documents_local_datasource.dart';
import 'package:proyecto_movil/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:proyecto_movil/features/documents/data/exporters/markdown_export.dart';
import 'package:proyecto_movil/features/documents/domain/entities/document_template.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';
import 'package:proyecto_movil/features/documents/domain/repositories/documents_repository.dart';

/// Qué hacer tras comparar teléfono y nube.
typedef SyncPlan = ({
  List<WorkDocument> push,
  List<WorkDocument> pull,
  List<WorkDocument> merged,
});

/// Por id gana el `updatedAt` más reciente; lo que falta de un lado se copia.
/// [merged] trae solo los no borrados, del más reciente al más antiguo.
SyncPlan planSync(List<WorkDocument> local, List<WorkDocument> remote) {
  final byLocal = {for (final d in local) d.id: d};
  final byRemote = {for (final d in remote) d.id: d};
  final push = <WorkDocument>[];
  final pull = <WorkDocument>[];
  final all = <WorkDocument>[];
  for (final id in {...byLocal.keys, ...byRemote.keys}) {
    final l = byLocal[id];
    final r = byRemote[id];
    if (r == null || (l != null && l.updatedAt.isAfter(r.updatedAt))) {
      push.add(l!);
      all.add(l);
    } else if (l == null || r.updatedAt.isAfter(l.updatedAt)) {
      pull.add(r);
      all.add(r);
    } else {
      all.add(l);
    }
  }
  final merged = [
    for (final d in all)
      if (!d.isDeleted) d,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return (push: push, pull: pull, merged: merged);
}

class DocumentsRepositoryImpl implements DocumentsRepository {
  DocumentsRepositoryImpl(
    this._local,
    this._remote, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DocumentsLocalDataSource _local;
  final DocumentsRemoteDataSource _remote;
  final DateTime Function() _clock;

  static final _random = Random.secure();

  /// UUID v4: el id nace en el teléfono, así se puede crear sin conexión.
  static String _uuid() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  List<WorkDocument> _visible(List<WorkDocument> docs) => [
    for (final d in docs)
      if (!d.isDeleted) d,
  ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<Either<Failure, List<WorkDocument>>> getLocal() async {
    try {
      return Right(_visible(await _local.readAll()));
    } on CacheException {
      return const Left(CacheFailure('No pudimos leer tus documentos.'));
    }
  }

  @override
  Future<Either<Failure, List<WorkDocument>>> sync() async {
    try {
      final plan = planSync(await _local.readAll(), await _remote.fetchAll());
      for (final d in plan.pull) {
        await _local.write(d);
      }
      await _remote.upsert(plan.push);
      await _uploadPendingImages();
      return Right(plan.merged);
    } on NetworkException {
      return const Left(
        NetworkFailure(
          'Sin conexión: tus documentos están a salvo en el teléfono y se '
          'subirán cuando vuelva internet.',
        ),
      );
    } on ServerException {
      return const Left(
        ServerFailure('No pudimos sincronizar con la nube. Reintenta luego.'),
      );
    } on CacheException {
      return const Left(CacheFailure('No pudimos leer tus documentos.'));
    }
  }

  @override
  Future<Either<Failure, WorkDocument>> create({
    required String title,
    required DocumentTemplate template,
    String? taskId,
  }) async {
    final now = _clock().toUtc();
    final name = title.trim().isEmpty ? 'Sin título' : title.trim();
    return save(
      WorkDocument(
        id: _uuid(),
        title: name.length > 120 ? name.substring(0, 120) : name,
        content: template.body(title: name, date: _clock()),
        updatedAt: now,
        taskId: taskId,
        template: template.name,
      ),
    );
  }

  @override
  Future<Either<Failure, WorkDocument>> save(WorkDocument document) async {
    try {
      await _local.write(document);
    } on CacheException {
      return const Left(
        CacheFailure('No pudimos guardar en el teléfono. Revisa el espacio.'),
      );
    }
    try {
      await _remote.upsert([document]);
    } on Exception {
      // Sin red o con la nube caída: queda en el teléfono y sube al sincronizar.
    }
    return Right(document);
  }

  @override
  Future<Either<Failure, Unit>> delete(WorkDocument document) async =>
      (await save(
        document.copyWith(
          updatedAt: _clock().toUtc(),
          deletedAt: _clock().toUtc(),
        ),
      )).map((_) => unit);

  /// Sube las imágenes que se agregaron sin conexión. Si falla, la próxima.
  Future<void> _uploadPendingImages() async {
    for (final (docId, name, file) in await _local.pendingImages()) {
      try {
        await _remote.uploadImage(docId, name, await file.readAsBytes());
        await _local.markUploaded(docId, name);
      } on Exception {
        return;
      }
    }
  }

  @override
  Future<Either<Failure, String>> addImage(
    String documentId,
    String sourcePath,
  ) async {
    final String name;
    try {
      name = await _local.addImage(documentId, sourcePath);
    } on CacheException {
      return const Left(CacheFailure('No pudimos agregar la imagen.'));
    }
    try {
      final file = await _local.imageFile(documentId, name);
      await _remote.uploadImage(documentId, name, await file!.readAsBytes());
      await _local.markUploaded(documentId, name);
    } on Exception {
      // Sin red: se sube al sincronizar.
    }
    return Right(name);
  }

  @override
  Future<Either<Failure, String?>> resolveImage(
    String documentId,
    String name,
  ) async {
    try {
      final local = await _local.imageFile(documentId, name);
      if (local != null) return Right(local.path);
      final bytes = await _remote.downloadImage(documentId, name);
      return Right((await _local.saveImage(documentId, name, bytes)).path);
    } on CacheException {
      return const Left(CacheFailure('No pudimos leer la imagen.'));
    } on Exception {
      return const Right(null); // sin red o no existe en la nube
    }
  }

  /// Bytes de las imágenes que usa el documento, para exportarlo.
  Future<Map<String, Uint8List>> _imagesOf(WorkDocument document) async {
    final out = <String, Uint8List>{};
    for (final name in imageNames(document.content)) {
      final path = (await resolveImage(document.id, name)).toNullable();
      if (path != null) out[name] = await File(path).readAsBytes();
    }
    return out;
  }

  @override
  Future<Either<Failure, Unit>> snapshot(WorkDocument document) async {
    try {
      final last = (await _local.versions(document.id)).firstOrNull;
      if (last == null ||
          last.content != document.content ||
          last.title != document.title) {
        await _local.addVersion(document);
      }
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure('No pudimos guardar el historial.'));
    }
  }

  @override
  Future<Either<Failure, List<WorkDocument>>> versions(
    String documentId,
  ) async {
    try {
      return Right(await _local.versions(documentId));
    } on CacheException {
      return const Left(CacheFailure('No pudimos leer el historial.'));
    }
  }

  @override
  Future<Either<Failure, String>> export(
    WorkDocument document,
    ExportFormat format,
  ) async {
    try {
      final images = await _imagesOf(document);
      final bytes = switch (format) {
        ExportFormat.pdf => await buildPdf(
          title: document.title,
          markdown: document.content,
          fonts: await _fonts(),
          images: images,
        ),
        ExportFormat.docx => buildDocx(
          markdown: document.content,
          images: images,
        ),
      };
      final dir = await _local.exportDir();
      final safe = document.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
          .trim();
      final file = File(
        '${dir.path}/${safe.isEmpty ? 'documento' : safe}.${format.name}',
      );
      await file.writeAsBytes(bytes, flush: true);
      return Right(file.path);
    } catch (_) {
      return const Left(CacheFailure('No pudimos generar el archivo.'));
    }
  }

  static PdfFonts? _cachedFonts;

  static Future<PdfFonts> _fonts() async {
    Future<pw.Font> load(String name) async =>
        pw.Font.ttf(await rootBundle.load('assets/google_fonts/$name'));
    return _cachedFonts ??= PdfFonts(
      regular: await load('DMSans-Regular.ttf'),
      bold: await load('DMSans-Bold.ttf'),
      mono: await load('DMMono-Medium.ttf'),
    );
  }
}
