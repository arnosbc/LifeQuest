import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_pressable.dart';

/// Estado de un nodo del camino estilo Duolingo.
enum QuestPathState { done, current, next, locked }

const _face = 72.0; // diámetro del botón
const _depth = 6.0; // base 3D bajo el botón
const _slot = 108.0; // caja fija de cada nodo: todos miden lo mismo
const _ring =
    _face + _depth + 22; // anillo: rodea cara + base con el mismo hueco
const _coinTop = (_slot - _face - _depth) / 2;

/// Poses de viaje que se turnan junto al camino (assets/images/mascota).
const _poses = [
  'saludando',
  'leyendo',
  'corriendo',
  'pensando',
  'meditando',
  'escalando',
];

/// Camino en zigzag con la mascota a los lados, como la senda de Duolingo.
/// [current] es el índice del nodo que toca (o null): la mascota se ve a
/// color hasta ahí y en gris más adelante. Con [celebrate] todas celebran.
class QuestPath extends StatelessWidget {
  const QuestPath({
    super.key,
    required this.nodes,
    this.current,
    this.celebrate = false,
  });

  final List<Widget> nodes;
  final int? current;
  final bool celebrate;

  static double _x(int i) => math.sin(i * math.pi / 3) * 0.55;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, node) in nodes.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Una mascota cada 3 nodos, del lado contrario, mirando al camino.
              if (i % 3 == 1)
                Align(
                  alignment: Alignment(_x(i) > 0.1 ? -0.9 : 0.9, 0),
                  child: MascotPose(
                    pose: celebrate
                        ? 'celebrando'
                        : _poses[(i ~/ 3) % _poses.length],
                    facesRight: _x(i) > 0.1,
                    dimmed: !celebrate && i > (current ?? nodes.length) + 1,
                  ),
                ),
              Align(alignment: Alignment(_x(i), 0), child: node),
            ],
          ),
        ),
    ],
  );
}

/// Nodo redondo del camino: hecho (dorado), actual (anillo y globo),
/// siguiente (tono suave) o bloqueado (gris). [icon] reemplaza el del estado.
class QuestPathNode extends StatelessWidget {
  const QuestPathNode({
    super.key,
    required this.state,
    required this.label,
    required this.semanticsLabel,
    this.sublabel,
    this.icon,
    this.bubble,
    this.busy = false,
    this.onTap,
  });

  final QuestPathState state;
  final String label;
  final String? sublabel;
  final String semanticsLabel;
  final IconData? icon;

  /// Globo sobre el nodo actual (p. ej. «EMPEZAR»).
  final String? bubble;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final (face, base, ink, stateIcon) = switch (state) {
      QuestPathState.done => (
        q.mustard,
        q.mustardInk,
        q.onAccent,
        Icons.check_rounded,
      ),
      QuestPathState.current => (
        q.accent,
        q.buttonShadow,
        q.onAccent,
        Icons.star_rounded,
      ),
      QuestPathState.next => (
        q.tint,
        q.tonalBorder,
        q.ink,
        Icons.play_arrow_rounded,
      ),
      QuestPathState.locked => (q.track, q.border, q.text3, Icons.lock_rounded),
    };
    final muted = state == QuestPathState.locked;
    final coin = QuestlyPressable(
      radius: _face / 2,
      onTap: busy ? null : onTap,
      semanticsLabel: semanticsLabel,
      // Base 3D: un círculo más oscuro asoma por debajo del botón.
      decoration: BoxDecoration(
        color: face,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: base, offset: const Offset(0, _depth))],
      ),
      child: SizedBox.square(
        dimension: _face,
        child: busy
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 3, color: ink),
              )
            : Icon(icon ?? stateIcon, size: 36, color: ink),
      ),
    );
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bubble != null) _Bubble(text: bubble!),
          SizedBox(
            width: _slot,
            height: _slot,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centrado en la moneda completa (cara + base 3D).
                if (state == QuestPathState.current)
                  Positioned(
                    top: _coinTop + (_face + _depth - _ring) / 2,
                    child: _Pulse(
                      child: Container(
                        width: _ring,
                        height: _ring,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: q.accent, width: 5),
                        ),
                      ),
                    ),
                  ),
                Positioned(top: _coinTop, child: coin),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: QText.label(muted ? q.text3 : q.text),
            ),
          ),
          if (sublabel != null)
            ExcludeSemantics(
              child: Text(
                sublabel!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QText.meta(q.text3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Globo con pico hacia abajo, como el «EMPEZAR» de la senda.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: q.card,
              borderRadius: BorderRadius.circular(QRadius.control),
              border: Border.all(color: q.border, width: 2),
            ),
            child: Text(text, style: QText.label(q.ink)),
          ),
          CustomPaint(
            size: const Size(16, 8),
            painter: _Tail(fill: q.card, stroke: q.border),
          ),
        ],
      ),
    );
  }
}

class _Tail extends CustomPainter {
  const _Tail({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size s) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width / 2, s.height)
      ..lineTo(s.width, 0);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_Tail old) => old.fill != fill || old.stroke != stroke;
}

/// Medallón decorativo de la mascota junto al camino; en gris si aún no se
/// llega a ese tramo.
/// Pose de la mascota (`assets/images/mascota`), decorativa. [pose] es el
/// nombre del archivo sin lado: saludando, leyendo, cofre, corona…
class MascotPose extends StatelessWidget {
  const MascotPose({
    super.key,
    required this.pose,
    this.facesRight = true,
    this.dimmed = false,
    this.size = 116,
  });

  final String pose;
  final bool facesRight;
  final bool dimmed;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      'assets/images/mascota/mascota_${pose}_${facesRight ? 'derecha' : 'izquierda'}.webp',
      width: size,
      height: size,
      // Si falta una pose, el camino sigue sin ella.
      errorBuilder: (_, _, _) => SizedBox.square(dimension: size),
    );
    if (dimmed) {
      img = Opacity(
        opacity: 0.4,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.33, 0.33, 0.33, 0, 0, //
            0.33, 0.33, 0.33, 0, 0,
            0.33, 0.33, 0.33, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: img,
        ),
      );
    }
    return ExcludeSemantics(child: img);
  }
}

/// Late suave del anillo del nodo actual: invita a tocarlo. Quieto si el
/// sistema pide reducir el movimiento.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
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
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(
      begin: 1.0,
      end: 1.07,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: widget.child,
  );
}
