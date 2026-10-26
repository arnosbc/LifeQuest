import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/stage/domain/repositories/stage_repository.dart';

/// Guarda un recurso (enlace) desde Quick Add.
class CreateResource implements UseCase<Unit, CreateResourceParams> {
  const CreateResource(this._repository);

  final StageRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CreateResourceParams params) =>
      _repository.createResource(title: params.title, url: params.url);
}

class CreateResourceParams extends Equatable {
  const CreateResourceParams({required this.title, required this.url});

  final String title;
  final String url;

  @override
  List<Object?> get props => [title, url];
}
