import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/documents/domain/entities/document_template.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';
import 'package:proyecto_movil/features/documents/domain/repositories/documents_repository.dart';

class GetLocalDocuments implements UseCase<List<WorkDocument>, NoParams> {
  const GetLocalDocuments(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, List<WorkDocument>>> call(NoParams params) =>
      _repository.getLocal();
}

class SyncDocuments implements UseCase<List<WorkDocument>, NoParams> {
  const SyncDocuments(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, List<WorkDocument>>> call(NoParams params) =>
      _repository.sync();
}

typedef NewDocumentParams = ({
  String title,
  DocumentTemplate template,
  String? taskId,
});

class CreateDocument implements UseCase<WorkDocument, NewDocumentParams> {
  const CreateDocument(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, WorkDocument>> call(NewDocumentParams params) =>
      _repository.create(
        title: params.title,
        template: params.template,
        taskId: params.taskId,
      );
}

class SaveDocument implements UseCase<WorkDocument, WorkDocument> {
  const SaveDocument(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, WorkDocument>> call(WorkDocument document) =>
      _repository.save(document);
}

class DeleteDocument implements UseCase<Unit, WorkDocument> {
  const DeleteDocument(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(WorkDocument document) =>
      _repository.delete(document);
}

/// Copia del documento en su historial (si cambió desde la última).
class SnapshotDocument implements UseCase<Unit, WorkDocument> {
  const SnapshotDocument(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(WorkDocument document) =>
      _repository.snapshot(document);
}

class GetDocumentVersions implements UseCase<List<WorkDocument>, String> {
  const GetDocumentVersions(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, List<WorkDocument>>> call(String documentId) =>
      _repository.versions(documentId);
}

typedef DocumentImageParams = ({String documentId, String path});

/// [DocumentImageParams.path] es la imagen elegida en la galería.
class AddDocumentImage implements UseCase<String, DocumentImageParams> {
  const AddDocumentImage(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, String>> call(DocumentImageParams params) =>
      _repository.addImage(params.documentId, params.path);
}

/// [DocumentImageParams.path] es el nombre de la imagen en el texto.
class ResolveDocumentImage implements UseCase<String?, DocumentImageParams> {
  const ResolveDocumentImage(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, String?>> call(DocumentImageParams params) =>
      _repository.resolveImage(params.documentId, params.path);
}

typedef ExportParams = ({WorkDocument document, ExportFormat format});

class ExportDocument implements UseCase<String, ExportParams> {
  const ExportDocument(this._repository);

  final DocumentsRepository _repository;

  @override
  Future<Either<Failure, String>> call(ExportParams params) =>
      _repository.export(params.document, params.format);
}
