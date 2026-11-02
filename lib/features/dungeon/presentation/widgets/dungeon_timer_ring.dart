import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Cronómetro de Foco: esfera de 60 marcas, arco con brillo que se vacía y
/// el tiempo en grande. El color lo da la fase ([accent]).
class DungeonTimerRing extends StatelessWidget {
  const DungeonTimerRing({
    super.key,
    required this.remaining,
    required this.total,
    required this.label,
    required this.footer,
    required this.accent,
  });

  final Duration remaining;
  final Duration total;

  /// «Foco», «Descanso», «En pausa» o «Sesión completa».
  final String label;

  /// Línea inferior, p. ej. «Guardando tu progreso…».
  final String footer;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final seconds = remaining.inSeconds;
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    final value = total.inSeconds == 0 ? 0.0 : seconds / total.inSeconds;
    return Semantics(
      label: '$label. Quedan ${seconds ~/ 60} minutos. $footer',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = math.min(box.maxWidth, 300.0);
          return Center(
            child: SizedBox.square(
              dimension: size,
              // El arco avanza en continuo entre los tics de un segundo.
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: value.clamp(0.0, 1.0)),
                duration: context.motion(const Duration(seconds: 1)),
                builder: (context, v, child) => CustomPaint(
                  painter: _DialPainter(
                    value: v,
                    accent: accent,
                    track: q.line,
                  ),
                  child: child,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(label, style: QText.meta(accent)),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: Text(
                        '$mm:$ss',
                        style: QText.numeral(q.text, size: size * .24),
                      ),
                    ),
                    if (footer.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(footer, style: QText.meta(q.text2)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.value,
    required this.accent,
    required this.track,
  });

  /// Fracción que queda (1 = recién empezado).
  final double value;
  final Color accent, track;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    const start = -math.pi / 2;

    // Esfera: 60 marcas, las de cada 5 más largas; las que quedan, en acento.
    for (var i = 0; i < 60; i++) {
      final a = start + i / 60 * 2 * math.pi;
      final major = i % 5 == 0;
      final left = i / 60 < value;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c + dir * (r - (major ? 14 : 9)),
        c + dir * (r - 2),
        Paint()
          ..color = left ? accent.withValues(alpha: major ? 1 : .6) : track
          ..strokeWidth = major ? 3 : 2
          ..strokeCap = StrokeCap.round,
      );
    }

    final arcRect = Rect.fromCircle(center: c, radius: r - 30);
    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
    );
    if (value <= 0) return;
    final sweep = value * 2 * math.pi;
    final arc = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    // Brillo: el mismo arco desenfocado por debajo.
    canvas.drawArc(
      arcRect,
      start,
      sweep,
      false,
      Paint()
        ..color = accent.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawArc(arcRect, start, sweep, false, arc);

    // Cabeza del arco.
    final head = start + sweep;
    final p = c + Offset(math.cos(head), math.sin(head)) * (r - 30);
    canvas.drawCircle(p, 9, Paint()..color = accent);
    canvas.drawCircle(p, 4, Paint()..color = track);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value || old.accent != accent || old.track != track;
}

/// Pista de ciclos: uno por bloque; hechos rellenos, el actual con borde.
class CycleTrack extends StatelessWidget {
  const CycleTrack({
    super.key,
    required this.total,
    required this.done,
    required this.accent,
  });

  final int total;
  final int done;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      label: '$done de $total ciclos hechos',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: i < done ? accent : q.line,
                  borderRadius: BorderRadius.circular(99),
                  border: i == done
                      ? Border.all(color: accent, width: 2)
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
