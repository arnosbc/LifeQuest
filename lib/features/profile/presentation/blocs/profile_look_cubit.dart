import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/profile_look_usecases.dart';

/// Apariencia del Perfil (avatar, luz, fondo). Cada cambio se ve al instante y
/// se guarda detrás; si no se puede leer, queda la de fábrica.
class ProfileLookCubit extends Cubit<ProfileLook> {
  ProfileLookCubit({
    required this._getLook,
    required this._saveLook,
    required this._importMedia,
  }) : super(const ProfileLook());

  final GetProfileLook _getLook;
  final SaveProfileLook _saveLook;
  final ImportProfileMedia _importMedia;

  Future<void> load() async =>
      (await _getLook(const NoParams())).match((_) {}, emit);

  Future<void> change(ProfileLook look) async {
    emit(look);
    await _saveLook(look);
  }

  /// Usa la foto de [sourcePath] como avatar. Devuelve el error, si hubo.
  Future<String?> usePhoto(String sourcePath) async =>
      (await _importMedia((
        sourcePath: sourcePath,
        kind: ProfileMediaKind.avatar,
      ))).match((failure) => failure.message, (path) {
        change(state.copyWith(avatar: AvatarStyle.photo, photoPath: path));
        return null;
      });

  /// Usa la imagen, GIF o video de [sourcePath] como fondo.
  Future<String?> useBackdrop(String sourcePath) async =>
      (await _importMedia((
        sourcePath: sourcePath,
        kind: ProfileMediaKind.backdrop,
      ))).match((failure) => failure.message, (path) {
        change(
          state.copyWith(backdrop: ProfileBackdrop.custom, backdropPath: path),
        );
        return null;
      });
}
