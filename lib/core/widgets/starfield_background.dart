import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Fondo de espacio (login, registro, Mazmorra y, en tema oscuro, el resto de
/// la app): estrellas que caen a distintas velocidades (las cercanas más rápido
/// y más grandes), titilan y, de vez en cuando, cruza una estrella fugaz. Con «Quitar animaciones» del sistema quedan quietas.
class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({super.key});

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  final _stars = _Star.generate(140, Random(7));
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _ticker.isActive) _ticker.stop();
    if (!reduceMotion && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _StarfieldPainter(_stars, _time),
        size: Size.infinite,
      ),
    ),
  );
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.alpha,
    required this.twinkleRate,
    required this.phase,
    required this.color,
  });

  /// Posición inicial normalizada (0–1) sobre el ancho y el alto.
  final double x;
  final double y;
  final double radius;

  /// Fracción del alto que recorre por segundo.
  final double speed;
  final double alpha;
  final double twinkleRate;
  final double phase;
  final Color color;

  // Tonos del logo: casi todas blancas, algunas cian y verdes.
  static const _cyan = Color(0xFF7FE8FF);
  static const _mint = Color(0xFFB6FFCF);

  static List<_Star> generate(int count, Random random) =>
      List.generate(count, (_) {
        final depth = random.nextDouble();
        final tint = random.nextDouble();
        return _Star(
          x: random.nextDouble(),
          y: random.nextDouble(),
          radius: 0.5 + depth * 1.6,
          speed: 0.004 + depth * 0.02,
          alpha: 0.35 + depth * 0.65,
          twinkleRate: 0.8 + random.nextDouble() * 2.5,
          phase: random.nextDouble() * 2 * pi,
          color: tint < 0.85 ? Colors.white : (tint < 0.93 ? _cyan : _mint),
        );
      });
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter(this.stars, this.time) : super(repaint: time);

  final List<_Star> stars;
  final ValueListenable<double> time;

  static const _spaceTop = Color(0xFF020A1A);
  static const _spaceBottom = Color(0xFF0B2347);
  static const _shootingPeriod = 7.0;
  static const _shootingDuration = 1.1;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_spaceTop, _spaceBottom],
        ).createShader(rect),
    );
    _glow(
      canvas,
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.65,
      const Color(0x2E00E5FF),
    );
    _glow(
      canvas,
      Offset(size.width * 0.1, size.height * 0.8),
      size.width * 0.75,
      const Color(0x2422E58A),
    );

    final t = time.value;
    final paint = Paint();
    for (final star in stars) {
      final y = (star.y + t * star.speed) % 1.0;
      final twinkle = 0.55 + 0.45 * sin(t * star.twinkleRate + star.phase);
      paint.color = star.color.withValues(alpha: star.alpha * twinkle);
      canvas.drawCircle(
        Offset(star.x * size.width, y * size.height),
        star.radius,
        paint,
      );
    }
    _shootingStar(canvas, size, t);
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  /// Una estrella fugaz cada [_shootingPeriod] s, en un punto distinto cada vez.
  void _shootingStar(Canvas canvas, Size size, double t) {
    final elapsed = t % _shootingPeriod;
    if (t < _shootingPeriod || elapsed > _shootingDuration) return;
    final progress = elapsed / _shootingDuration;
    final random = Random((t / _shootingPeriod).floor());
    final start = Offset(
      size.width * (0.4 + 0.55 * random.nextDouble()),
      size.height * 0.35 * random.nextDouble(),
    );
    final travel = Offset(-size.width * 0.55, size.width * 0.33);
    final head = start + travel * progress;
    final tail = head - travel * 0.22;
    final opacity = sin(progress * pi);
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: opacity),
          ],
        ).createShader(Rect.fromPoints(tail, head)),
    );
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) => false;
}
