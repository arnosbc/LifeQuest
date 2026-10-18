part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar el perfil.
class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileIdentitySaved extends ProfileEvent {
  const ProfileIdentitySaved({
    required this.displayName,
    this.identityStatement,
  });

  final String displayName;
  final String? identityStatement;

  @override
  List<Object?> get props => [displayName, identityStatement];
}

class ProfileSkillCreated extends ProfileEvent {
  const ProfileSkillCreated(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class ProfileSkillRenamed extends ProfileEvent {
  const ProfileSkillRenamed({required this.skillId, required this.name});

  final String skillId;
  final String name;

  @override
  List<Object?> get props => [skillId, name];
}

class ProfileSkillDeleted extends ProfileEvent {
  const ProfileSkillDeleted(this.skillId);

  final String skillId;

  @override
  List<Object?> get props => [skillId];
}
