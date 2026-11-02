import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/starfield_background.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';

/// Colores de la luz del avatar (null = sin luz).
Color? profileGlowColor(ProfileGlow glow) => switch (glow) {
  ProfileGlow.none => null,
  ProfileGlow.lavender => const Color(0xFFC9B6FF),
  ProfileGlow.gold => const Color(0xFFFFD36B),
  ProfileGlow.pink => const Color(0xFFFF8AD8),
  ProfileGlow.cyan => const Color(0xFF6BE7FF),
  ProfileGlow.green => const Color(0xFF7CF2A8),
};

/// Animación en bucle de 0 a 1 y vuelta; quieta en 0,5 si el sistema pide
/// reducir movimiento.
class _Loop extends StatefulWidget {
  const _Loop({required this.period, required this.builder});

  final Duration period;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(
      context,
      MediaQuery.disableAnimationsOf(context) ? .5 : _c.value,
    ),
  );
}

/// Avatar del Perfil: paisaje, foto, emoji o personaje animado, con su luz.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.look, this.size = 96});

  final ProfileLook look;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glow = profileGlowColor(look.glow);
    Widget frame(double t) => Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: glow ?? Colors.white, width: 3),
        boxShadow: glow == null
            ? null
            : [
                BoxShadow(
                  color: glow.withValues(alpha: .45 + .4 * t),
                  blurRadius: 12 + 18 * t,
                  spreadRadius: 1 + 5 * t,
                ),
              ],
      ),
      child: ExcludeSemantics(child: _content(t)),
    );
    // Sin luz ni personaje no hay nada que animar.
    if (glow == null && look.avatar != AvatarStyle.character) return frame(.5);
    return _Loop(
      period: const Duration(milliseconds: 1600),
      builder: (context, t) => frame(t),
    );
  }

  Widget _content(double t) {
    final emojiSize = size * .55;
    switch (look.avatar) {
      case AvatarStyle.photo when look.photoPath != null:
        return Image.file(
          File(look.photoPath!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const LifeQuestLandscape(hiker: true),
        );
      case AvatarStyle.emoji:
        return ColoredBox(
          color: const Color(0xFFEFE9FB),
          child: Center(
            child: Text(look.emoji, style: TextStyle(fontSize: emojiSize)),
          ),
        );
      case AvatarStyle.character:
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFFF4EEFF), Color(0xFFC9B6F0)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Flota y se balancea.
              Transform.translate(
                offset: Offset(0, 4 - 8 * t),
                child: Transform.rotate(
                  angle: (t - .5) * .18,
                  child: Text(
                    look.character,
                    style: TextStyle(fontSize: emojiSize),
                  ),
                ),
              ),
              // Destellos que se turnan.
              Positioned(
                top: size * .1,
                right: size * .14,
                child: Opacity(
                  opacity: t,
                  child: Text('✨', style: TextStyle(fontSize: size * .18)),
                ),
              ),
              Positioned(
                bottom: size * .14,
                left: size * .12,
                child: Opacity(
                  opacity: 1 - t,
                  child: Text('✨', style: TextStyle(fontSize: size * .14)),
                ),
              ),
            ],
          ),
        );
      case AvatarStyle.landscape || AvatarStyle.photo:
        return const LifeQuestLandscape(hiker: true);
    }
  }
}

/// Fondo de la cabecera del Perfil. Todos dejan el texto blanco legible.
class ProfileBackdropView extends StatelessWidget {
  const ProfileBackdropView({super.key, required this.look});

  final ProfileLook look;

  static const _lavender = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7C5CC4), Color(0xFF5B3FA8)],
  );

  @override
  Widget build(BuildContext context) => switch (look.backdrop) {
    ProfileBackdrop.lavender => const DecoratedBox(
      decoration: BoxDecoration(gradient: _lavender),
    ),
    ProfileBackdrop.aurora => _Loop(
      period: const Duration(seconds: 6),
      builder: (context, t) {
        final a = t * math.pi;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.cos(a), math.sin(a)),
              end: Alignment(-math.cos(a), -math.sin(a)),
              colors: const [
                Color(0xFF3B2A72),
                Color(0xFF6A3FB5),
                Color(0xFF8E3A84),
                Color(0xFF24508F),
              ],
            ),
          ),
        );
      },
    ),
    ProfileBackdrop.stars => const ColoredBox(
      color: Color(0xFF1C1538),
      child: StarfieldBackground(),
    ),
    ProfileBackdrop.custom when look.backdropPath != null => Stack(
      fit: StackFit.expand,
      children: [
        if (look.backdropIsVideo)
          _VideoBackdrop(path: look.backdropPath!)
        else
          // Image.file también anima los GIF.
          Image.file(
            File(look.backdropPath!),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const DecoratedBox(
              decoration: BoxDecoration(gradient: _lavender),
            ),
          ),
        // Velo para que el texto blanco se lea sobre cualquier fondo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0x99000000)],
            ),
          ),
        ),
      ],
    ),
    ProfileBackdrop.custom => const DecoratedBox(
      decoration: BoxDecoration(gradient: _lavender),
    ),
    ProfileBackdrop.mountains => const Stack(
      fit: StackFit.expand,
      children: [
        LifeQuestLandscape(),
        // Oscurece para que el texto blanco se lea sobre el cielo claro.
        ColoredBox(color: Color(0x993B2A72)),
      ],
    ),
  };
}

/// Video del fondo: en bucle, sin sonido y recortado para llenar. Se reproduce
/// aunque el sistema tenga las animaciones apagadas: el usuario lo eligió.
class _VideoBackdrop extends StatefulWidget {
  const _VideoBackdrop({required this.path});

  final String path;

  @override
  State<_VideoBackdrop> createState() => _VideoBackdropState();
}

class _VideoBackdropState extends State<_VideoBackdrop> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(_VideoBackdrop old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _controller?.dispose();
      _open();
    }
  }

  Future<void> _open() async {
    final c = VideoPlayerController.file(File(widget.path));
    _controller = c;
    try {
      await c.initialize();
    } catch (_) {
      return; // archivo dañado o formato no soportado: queda el velo
    }
    await c.setLooping(true);
    await c.setVolume(0);
    if (!mounted || _controller != c) return;
    await c.play();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(color: Color(0xFF3B2A72));
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
