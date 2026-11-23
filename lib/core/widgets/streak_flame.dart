import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Llama de la racha. Parpadea suave mientras hay racha y, cuando [streak]
/// sube, salta con rebote, brilla y suelta chispas. En 0 queda gris y quieta.
/// Con «reducir movimiento» del sistema no se anima. Es decorativa: el número
/// de al lado ya dice la racha.
class StreakFlame extends StatefulWidget {
  const StreakFlame({super.key, required this.streak, this.size = 64});

  final int streak;
  final double size;

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with TickerProviderStateMixin {
  late final AnimationController _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool get _quiet => context.motion(QMotion.fade) == Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFlicker();
  }

  @override
  void didUpdateWidget(StreakFlame old) {
    super.didUpdateWidget(old);
    if (widget.streak > old.streak && !_quiet) _burst.forward(from: 0);
    _syncFlicker();
  }

  void _syncFlicker() {
    if (widget.streak > 0 && !_quiet) {
      if (!_flicker.isAnimating) _flicker.repeat();
    } else {
      _flicker.stop();
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viva = widget.streak > 0;
    final q = context.q;
    // Paleta de Questly: rojo de marca arriba, mostaza de racha abajo.
    final colores = _Colores(
      exterior: [
        QColors.mark,
        QColors.markDark,
        q.dark ? q.mustardInk : q.mustard,
      ],
      nucleo: [q.dark ? q.mustardInk : QColors.mustardTint, QColors.bg],
      chispa: q.dark ? q.mustardInk : q.mustard,
      apagada: q.text2,
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.15,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flicker, _burst]),
          builder: (context, _) => CustomPaint(
            painter: _FlamePainter(
              t: _flicker.value,
              burst: _burst.value,
              bursting: _burst.isAnimating,
              viva: viva,
              colores: colores,
            ),
          ),
        ),
      ),
    );
  }
}

class _Colores {
  const _Colores({
    required this.exterior,
    required this.nucleo,
    required this.chispa,
    required this.apagada,
  });

  final List<Color> exterior, nucleo;
  final Color chispa, apagada;

  @override
  bool operator ==(Object o) =>
      o is _Colores &&
      o.chispa == chispa &&
      o.apagada == apagada &&
      o.exterior.first == exterior.first;

  @override
  int get hashCode => Object.hash(chispa, apagada, exterior.first);
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({
    required this.t,
    required this.burst,
    required this.bursting,
    required this.viva,
    required this.colores,
  });

  /// Fase del parpadeo (0–1, en bucle).
  final double t;

  /// Avance del festejo (0–1).
  final double burst;
  final bool bursting;
  final bool viva;
  final _Colores colores;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Offset(w / 2, h);

    // Festejo: salto con rebote, brillo y chispas.
    final salto = bursting ? _rebote(burst) : 1.0;
    if (bursting) {
      final brillo = math.sin(burst * math.pi);
      canvas.drawCircle(
        Offset(w / 2, h * 0.58),
        w * (0.45 + 0.35 * burst),
        Paint()
          ..color = colores.chispa.withValues(alpha: 0.45 * brillo)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.18),
      );
      final chispas = Paint()
        ..color = colores.chispa.withValues(alpha: 1 - burst);
      for (var i = 0; i < 8; i++) {
        final a = -math.pi / 2 + (i - 3.5) * 0.42;
        final d = w * (0.35 + 0.65 * Curves.easeOut.transform(burst));
        canvas.drawCircle(
          Offset(w / 2 + math.cos(a) * d, h * 0.55 + math.sin(a) * d),
          w * 0.045 * (1 - burst * 0.6),
          chispas,
        );
      }
    }

    // Parpadeo: estira, se inclina y la punta se mece.
    final s1 = math.sin(t * 2 * math.pi);
    final s2 = math.sin(t * 4 * math.pi + 1.3);
    final estira = viva ? 1 + 0.05 * s1 : 1.0;
    final mece = viva ? 0.06 * s2 : 0.0;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(salto, salto * estira);
    canvas.translate(-base.dx, -base.dy);

    final exterior = _llama(w, h, mece);
    canvas.drawPath(
      exterior,
      Paint()
        ..shader =
            (viva
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: colores.exterior,
                        stops: const [0, 0.45, 1],
                      )
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colores.apagada.withValues(alpha: 0.55),
                          colores.apagada,
                        ],
                      ))
                .createShader(Offset.zero & size),
    );
    if (viva) {
      canvas.drawPath(
        _nucleo(w, h, mece * 1.6),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colores.nucleo,
          ).createShader(Offset.zero & size),
      );
    }
    canvas.restore();
  }

  /// Rebote: crece hasta ~1,45 y vuelve con un pequeño temblor.
  static double _rebote(double p) {
    if (p < 0.25) return 1 + 0.45 * Curves.easeOut.transform(p / 0.25);
    return 1 + 0.45 * (1 - Curves.elasticOut.transform((p - 0.25) / 0.75));
  }

  /// Silueta de la llama con dos lenguas; [m] mece la punta.
  static Path _llama(double w, double h, double m) {
    Offset p(double x, double y) => Offset(w * (x + m * (1 - y)), h * y);
    final a = p(0.5, 1.0);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(
        p(0.12, 1).dx,
        p(0.12, 1).dy,
        p(0.02, 0.70).dx,
        p(0.02, 0.70).dy,
        p(0.18, 0.47).dx,
        p(0.18, 0.47).dy,
      )
      ..cubicTo(
        p(0.27, 0.34).dx,
        p(0.27, 0.34).dy,
        p(0.26, 0.22).dx,
        p(0.26, 0.22).dy,
        p(0.22, 0.12).dx,
        p(0.22, 0.12).dy,
      )
      ..cubicTo(
        p(0.40, 0.20).dx,
        p(0.40, 0.20).dy,
        p(0.48, 0.32).dx,
        p(0.48, 0.32).dy,
        p(0.49, 0.40).dx,
        p(0.49, 0.40).dy,
      )
      ..cubicTo(
        p(0.55, 0.25).dx,
        p(0.55, 0.25).dy,
        p(0.66, 0.12).dx,
        p(0.66, 0.12).dy,
        p(0.60, 0.0).dx,
        p(0.60, 0.0).dy,
      )
      ..cubicTo(
        p(0.86, 0.18).dx,
        p(0.86, 0.18).dy,
        p(0.99, 0.48).dx,
        p(0.99, 0.48).dy,
        p(0.93, 0.70).dx,
        p(0.93, 0.70).dy,
      )
      ..cubicTo(
        p(0.88, 0.91).dx,
        p(0.88, 0.91).dy,
        p(0.72, 1).dx,
        p(0.72, 1).dy,
        a.dx,
        a.dy,
      )
      ..close();
  }

  /// Centro claro de la llama.
  static Path _nucleo(double w, double h, double m) {
    Offset p(double x, double y) => Offset(w * (x + m * (1 - y)), h * y);
    final a = p(0.5, 0.97);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(
        p(0.29, 0.97).dx,
        p(0.29, 0.97).dy,
        p(0.26, 0.80).dx,
        p(0.26, 0.80).dy,
        p(0.36, 0.67).dx,
        p(0.36, 0.67).dy,
      )
      ..cubicTo(
        p(0.43, 0.58).dx,
        p(0.43, 0.58).dy,
        p(0.47, 0.52).dx,
        p(0.47, 0.52).dy,
        p(0.50, 0.44).dx,
        p(0.50, 0.44).dy,
      )
      ..cubicTo(
        p(0.62, 0.56).dx,
        p(0.62, 0.56).dy,
        p(0.75, 0.70).dx,
        p(0.75, 0.70).dy,
        p(0.71, 0.83).dx,
        p(0.71, 0.83).dy,
      )
      ..cubicTo(
        p(0.67, 0.95).dx,
        p(0.67, 0.95).dy,
        p(0.60, 0.97).dx,
        p(0.60, 0.97).dy,
        a.dx,
        a.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_FlamePainter old) =>
      old.t != t ||
      old.burst != burst ||
      old.bursting != bursting ||
      old.viva != viva ||
      old.colores != colores;
}
