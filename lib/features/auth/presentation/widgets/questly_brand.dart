import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Aparece al entrar: sube y se desvanece tras [delay]. Con «reducir
/// movimiento» del sistema se muestra de una vez.
class Aparece extends StatefulWidget {
  const Aparece({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.desde = 18,
    this.escala = false,
  });

  final Widget child;
  final Duration delay;

  /// Píxeles que sube al aparecer.
  final double desde;

  /// Además crece con un pequeño rebote (para el logo).
  final bool escala;

  @override
  State<Aparece> createState() => _ApareceState();
}

class _ApareceState extends State<Aparece> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.motion(QMotion.fade) == Duration.zero) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
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
    builder: (context, child) {
      final t = QMotion.easeOut.transform(_c.value);
      final s = widget.escala
          ? Curves.elasticOut.transform(_c.value).clamp(0.0, 1.2)
          : 1.0;
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * widget.desde),
          child: Transform.scale(
            scale: widget.escala ? 0.6 + 0.4 * s : 1,
            child: child,
          ),
        ),
      );
    },
    child: widget.child,
  );
}

/// Logo de la app (el mismo del ícono) con su nombre y el lema.
class QuestlyBrand extends StatelessWidget {
  const QuestlyBrand({
    super.key,
    this.logo = 72,
    this.color,
    this.lemaColor,
    this.animar = true,
  });

  final double logo;
  final Color? color;
  final Color? lemaColor;
  final bool animar;

  static const lema = 'AVANZA CON RITMO Y PROGRESO REAL';

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    Widget paso(int i, Widget w, {bool escala = false}) => animar
        ? Aparece(
            delay: Duration(milliseconds: 120 * i),
            escala: escala,
            child: w,
          )
        : w;
    return Semantics(
      header: true,
      label: 'Questly. Avanza con ritmo y progreso real.',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          paso(
            0,
            ClipRRect(
              borderRadius: BorderRadius.circular(logo * 0.24),
              child: Image.asset(
                'assets/images/marca/logo_questly.png',
                width: logo,
                height: logo,
                filterQuality: FilterQuality.medium,
              ),
            ),
            escala: true,
          ),
          SizedBox(height: logo * 0.04),
          paso(
            1,
            Text(
              'Questly',
              style: TextStyle(
                fontFamily: QText.family,
                fontSize: logo * 0.36,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
                color: color ?? q.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          paso(
            2,
            Text(
              lema,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: QText.family,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: lemaColor ?? q.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
