import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Unit;

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/create_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/delete_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/rename_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/set_active_title.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this._getCharacterProfile,
    required this._updateIdentity,
    required this._createSkill,
    required this._renameSkill,
    required this._deleteSkill,
    required this._setActiveTitle,
  }) : super(const ProfileInitial()) {
    // droppable: toques repetidos mientras se guarda se ignoran.
    on<ProfileRequested>(_onRequested, transformer: droppable());
    on<ProfileIdentitySaved>(
      (event, emit) => _save(
        emit,
        () => _updateIdentity(
          UpdateIdentityParams(
            displayName: event.displayName,
            identityStatement: event.identityStatement,
          ),
        ),
        'Identidad guardada.',
      ),
      transformer: droppable(),
    );
    on<ProfileSkillCreated>(
      (event, emit) => _save(
        emit,
        () => _createSkill(event.name),
        'Skill «${event.name.trim()}» creada.',
      ),
      transformer: droppable(),
    );
    on<ProfileSkillRenamed>(
      (event, emit) => _save(
        emit,
        () => _renameSkill(
          RenameSkillParams(skillId: event.skillId, name: event.name),
        ),
        'Skill renombrada.',
      ),
      transformer: droppable(),
    );
    on<ProfileSkillDeleted>(
      (event, emit) =>
          _save(emit, () => _deleteSkill(event.skillId), 'Skill eliminada.'),
      transformer: droppable(),
    );
    on<ProfileActiveTitleChanged>(
      (event, emit) => _save(
        emit,
        () => _setActiveTitle(event.titleId),
        _titleMessage(event.titleId),
      ),
      transformer: droppable(),
    );
  }

  final GetCharacterProfile _getCharacterProfile;
  final UpdateIdentity _updateIdentity;
  final CreateSkill _createSkill;
  final RenameSkill _renameSkill;
  final DeleteSkill _deleteSkill;
  final SetActiveTitle _setActiveTitle;

  String _titleMessage(String? titleId) {
    if (titleId == null) return 'Ya no muestras ningún título.';
    final current = state;
    final name = current is ProfileSuccess
        ? current.profile.earnedTitles
              .where((title) => title.id == titleId)
              .firstOrNull
              ?.name
        : null;
    return name == null ? 'Título actualizado.' : 'Ahora luces «$name».';
  }

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    emit(
      current is ProfileSuccess
          ? ProfileSuccess(current.profile, saving: true)
          : const ProfileLoading(),
    );
    final result = await _getCharacterProfile(const NoParams());
    emit(
      result.match(
        (failure) => current is ProfileSuccess
            ? ProfileSuccess(current.profile, message: failure.message)
            : ProfileFailure(failure.message),
        ProfileSuccess.new,
      ),
    );
  }

  /// Aplica un cambio y relee el perfil para mostrar lo que guardó el servidor.
  Future<void> _save(
    Emitter<ProfileState> emit,
    Future<Either<Failure, Unit>> Function() action,
    String successMessage,
  ) async {
    final current = state;
    if (current is! ProfileSuccess) return;
    emit(ProfileSuccess(current.profile, saving: true));

    if (await action() case Left(value: final failure)) {
      emit(ProfileSuccess(current.profile, message: failure.message));
      return;
    }
    final reloaded = await _getCharacterProfile(const NoParams());
    emit(
      reloaded.match(
        (failure) => ProfileSuccess(current.profile, message: failure.message),
        (profile) => ProfileSuccess(profile, message: successMessage),
      ),
    );
  }
}
