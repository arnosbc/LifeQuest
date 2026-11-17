import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/documents/domain/entities/document_template.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';

enum ExportFormat { pdf, docx }

/// Documentos guardados en el teléfono y sincronizados con la nube.
abstract interface class DocumentsRepository {
  /// Los del teléfono, sin esperar a la red.
  Future<Either<Failure, List<WorkDocument>>> getLocal();

  /// Une teléfono y nube (gana el cambio más reciente) y devuelve el resultado.
  Future<Either<Failure, List<WorkDocument>>> sync();

  /// Crea un documento; con [taskId] queda vinculado a esa tarea.
  Future<Either<Failure, WorkDocument>> create({
    required String title,
    required DocumentTemplate template,
    String? taskId,
  });

  /// Guarda en el teléfono y, si hay red, en la nube. Sin red no es error.
  Future<Either<Failure, WorkDocument>> save(WorkDocument document);

  Future<Either<Failure, Unit>> delete(WorkDocument document);

  /// Copia en el historial, salvo que sea igual a la última guardada.
  Future<Either<Failure, Unit>> snapshot(WorkDocument document);

  /// Historial del documento, de la copia más reciente a la más antigua.
  Future<Either<Failure, List<WorkDocument>>> versions(String documentId);

  /// Copia la imagen al documento (y a la nube si hay red); devuelve el
  /// nombre con el que se escribe en el texto: `![…](img/nombre)`.
  Future<Either<Failure, String>> addImage(
    String documentId,
    String sourcePath,
  );

  /// Ruta local de la imagen; si falta en el teléfono la baja de la nube.
  /// Right(null) si no está en ningún lado.
  Future<Either<Failure, String?>> resolveImage(String documentId, String name);

  /// Genera el archivo y devuelve su ruta (para compartirlo).
  Future<Either<Failure, String>> export(
    WorkDocument document,
    ExportFormat format,
  );
}
