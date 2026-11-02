import 'package:equatable/equatable.dart';

/// Qué se ve dentro del círculo del avatar.
enum AvatarStyle { landscape, photo, emoji, character }

/// Luz que rodea el avatar (late suave).
enum ProfileGlow { none, lavender, gold, pink, cyan, green }

/// Fondo de la cabecera del Perfil.
enum ProfileBackdrop { lavender, aurora, stars, mountains, custom }

/// Cómo se ve el Perfil en este dispositivo: avatar, luz y fondo.
class ProfileLook extends Equatable {
  const ProfileLook({
    this.avatar = AvatarStyle.landscape,
    this.emoji = '😎',
    this.character = '🧙',
    this.photoPath,
    this.backdropPath,
    this.glow = ProfileGlow.lavender,
    this.backdrop = ProfileBackdrop.lavender,
  });

  final AvatarStyle avatar;
  final String emoji;

  /// Personaje animado (un emoji que flota con destellos).
  final String character;

  /// Copia de la foto elegida, dentro de la carpeta de la app.
  final String? photoPath;

  /// Copia del fondo propio (imagen, GIF o video) para [ProfileBackdrop.custom].
  final String? backdropPath;
  final ProfileGlow glow;
  final ProfileBackdrop backdrop;

  ProfileLook copyWith({
    AvatarStyle? avatar,
    String? emoji,
    String? character,
    String? photoPath,
    String? backdropPath,
    ProfileGlow? glow,
    ProfileBackdrop? backdrop,
  }) => ProfileLook(
    avatar: avatar ?? this.avatar,
    emoji: emoji ?? this.emoji,
    character: character ?? this.character,
    photoPath: photoPath ?? this.photoPath,
    backdropPath: backdropPath ?? this.backdropPath,
    glow: glow ?? this.glow,
    backdrop: backdrop ?? this.backdrop,
  );

  @override
  List<Object?> get props => [
    avatar,
    emoji,
    character,
    photoPath,
    backdropPath,
    glow,
    backdrop,
  ];

  /// El fondo propio es un video (se reproduce en bucle y sin sonido).
  bool get backdropIsVideo => switch (backdropPath?.split('.').last) {
    'mp4' || 'mov' || 'webm' || 'mkv' || '3gp' || 'm4v' => true,
    _ => false,
  };
}
