import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';

/// Lanza una lluvia corta de confeti sobre toda la pantalla (no bloquea
/// toques). No hace nada si el sistema pide reducir el movimiento.
void showConfetti(BuildContext context, {int pieces = 70}) {
  if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final q = context.q;
  final colors = [q.accent, q.mustard, q.coral, q.river, q.tint];
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: _Confetti(
        pieces: pieces,
        colors: colors,
        onDone: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  const _Confetti({
    required this.pieces,
    required this.colors,
    required this.onDone,
  });

  final int pieces;
  final List<Color> colors;
  final VoidCallback onDone;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward().whenComplete(widget.onDone);

  late final List<_Piece> _pieces = () {
    final r = math.Random();
    return List.generate(
      widget.pieces,
      (i) => _Piece(
        x: r.nextDouble(),
        // Sale desde arriba con un empujón hacia los lados.
        vx: (r.nextDouble() - 0.5) * 0.5,
        vy: 0.2 + r.nextDouble() * 0.5,
        spin: (r.nextDouble() - 0.5) * 12,
        size: 6 + r.nextDouble() * 6,
        color: widget.colors[i % widget.colors.length],
      ),
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => CustomPaint(
      size: Size.infinite,
      painter: _ConfettiPainter(_pieces, _c.value),
    ),
  );
}

class _Piece {
  const _Piece({
    required this.x,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x, vx, vy, spin, size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Se desvanece en el último tercio.
    final fade = t < 0.66 ? 1.0 : (1 - t) / 0.34;
    for (final p in pieces) {
      final x = (p.x + p.vx * t) * size.width;
      // Cae con gravedad: arranca un poco por encima de la pantalla.
      final y = (-0.05 + p.vy * t + 0.9 * t * t) * size.height;
      paint.color = p.color.withValues(alpha: fade.clamp(0, 1));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.spin * t)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
