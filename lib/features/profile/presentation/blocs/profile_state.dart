part of 'profile_bloc.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Primera carga, sin datos que mostrar todavía.
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Perfil listo. Guardar o refrescar no lo quita de la pantalla.
class ProfileSuccess extends ProfileState {
  const ProfileSuccess(this.profile, {this.saving = false, this.message});

  final CharacterProfile profile;

  /// Hay un cambio o un refresco en curso.
  final bool saving;

  /// Aviso puntual para un snackbar (confirmación o error).
  final String? message;

  @override
  List<Object?> get props => [profile, saving, message];
}

/// La primera carga falló; no hay datos que mostrar.
class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
