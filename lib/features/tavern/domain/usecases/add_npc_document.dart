import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/repositories/tavern_repository.dart';

/// Adjunta un documento de contexto al NPC (PDF, Word o Markdown, máx.
/// 10 MB). Revisa el formato y el tamaño antes de subirlo.
class AddNpcDocument implements UseCase<Unit, NewNpcDocument> {
  const AddNpcDocument(this._repository);

  final TavernRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NewNpcDocument document) async {
    if (!NewNpcDocument.extensions.contains(document.extension)) {
      return const Left(
        ValidationFailure('Sube el documento en PDF, Word (.docx) o Markdown.'),
      );
    }
    if (document.bytes.isEmpty) {
      return const Left(ValidationFailure('Ese documento está vacío.'));
    }
    if (document.bytes.length > NewNpcDocument.maxBytes) {
      return const Left(
        ValidationFailure(
          'El documento pesa más de 10 MB. Prueba con uno más ligero.',
        ),
      );
    }
    if (document.title.isEmpty) {
      return const Left(ValidationFailure('El documento necesita un nombre.'));
    }
    return _repository.addDocument(document);
  }
}
