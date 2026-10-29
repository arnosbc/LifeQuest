import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Guarda un recurso desde Quick Add: enlace, nota o documento. Revisa lo
/// que el servidor rechazaría antes de subir nada.
class CreateResource implements UseCase<Unit, NewResource> {
  const CreateResource(this._repository);

  final StageRepository _repository;

  static final _url = RegExp(r'^https?://\S+$', caseSensitive: false);

  @override
  Future<Either<Failure, Unit>> call(NewResource params) async {
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure('Dale un nombre a tu recurso.'));
    }
    final problem = switch (params.kind) {
      ResourceKind.link when !_url.hasMatch(params.url?.trim() ?? '') =>
        'Escribe un enlace que empiece por http:// o https://',
      ResourceKind.note when (params.content?.trim() ?? '').isEmpty =>
        'Escribe el contenido de la nota.',
      ResourceKind.note
          when params.content!.trim().length > NewResource.maxNoteLength =>
        'La nota puede tener hasta ${NewResource.maxNoteLength} caracteres.',
      ResourceKind.document
          when params.bytes == null || params.bytes!.isEmpty =>
        'Elige el documento que quieres guardar.',
      ResourceKind.document
          when !NewResource.extensions.contains(params.extension) =>
        'Ese formato no se puede guardar. Prueba con PDF, Word, Excel, '
            'PowerPoint, Markdown, texto o imagen.',
      ResourceKind.document when params.bytes!.length > NewResource.maxBytes =>
        'El documento pesa más de 10 MB. Prueba con uno más ligero.',
      _ => null,
    };
    if (problem != null) return Left(ValidationFailure(problem));
    return _repository.createResource(params);
  }
}
