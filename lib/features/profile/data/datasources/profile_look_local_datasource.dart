import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';

/// Apariencia del Perfil guardada en el dispositivo. Lanza [CacheException].
abstract interface class ProfileLookLocalDataSource {
  /// Null si nunca se guardó.
  Future<ProfileLook?> getLook();

  Future<void> saveLook(ProfileLook look);

  /// Copia el archivo en la carpeta de la app y devuelve la ruta de la copia.
  /// [kind] separa la foto del avatar ('avatar') del fondo ('backdrop').
  Future<String> importMedia(String sourcePath, {required String kind});
}

class ProfileLookLocalDataSourceImpl implements ProfileLookLocalDataSource {
  const ProfileLookLocalDataSourceImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _key = 'profile_look';

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw CacheException('$error');
    }
  }

  @override
  Future<ProfileLook?> getLook() => _guard(() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.asNameMap()[name] ?? fallback;
    const d = ProfileLook();
    return ProfileLook(
      avatar: pick(AvatarStyle.values, json['avatar'], d.avatar),
      emoji: json['emoji'] as String? ?? d.emoji,
      character: json['character'] as String? ?? d.character,
      photoPath: json['photo'] as String?,
      backdropPath: json['backdrop_file'] as String?,
      glow: pick(ProfileGlow.values, json['glow'], d.glow),
      backdrop: pick(ProfileBackdrop.values, json['backdrop'], d.backdrop),
    );
  });

  @override
  Future<void> saveLook(ProfileLook look) => _guard(
    () => _prefs.setString(
      _key,
      jsonEncode({
        'avatar': look.avatar.name,
        'emoji': look.emoji,
        'character': look.character,
        'photo': look.photoPath,
        'backdrop_file': look.backdropPath,
        'glow': look.glow.name,
        'backdrop': look.backdrop.name,
      }),
    ),
  );

  @override
  Future<String> importMedia(String sourcePath, {required String kind}) =>
      _guard(() async {
        final dir = await getApplicationDocumentsDirectory();
        // La extensión dice si es video; el nombre cambia cada vez porque
        // Image.file no vuelve a leer una ruta que ya cacheó.
        final dot = sourcePath.lastIndexOf('.');
        final ext = dot < 0
            ? 'jpg'
            : sourcePath.substring(dot + 1).toLowerCase();
        final target =
            '${dir.path}/${kind}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await File(sourcePath).copy(target);
        for (final old in dir.listSync().whereType<File>()) {
          final name = old.uri.pathSegments.last;
          if (old.path != target && name.startsWith('${kind}_')) {
            old.deleteSync();
          }
        }
        return target;
      });
}
