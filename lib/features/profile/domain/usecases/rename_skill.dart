import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/repositories/profile_repository.dart';

/// Cambia el nombre de una skill; conserva su nivel y su XP.
class RenameSkill implements UseCase<Unit, RenameSkillParams> {
  const RenameSkill(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RenameSkillParams params) =>
      _repository.renameSkill(skillId: params.skillId, name: params.name);
}

class RenameSkillParams extends Equatable {
  const RenameSkillParams({required this.skillId, required this.name});

  final String skillId;
  final String name;

  @override
  List<Object?> get props => [skillId, name];
}
