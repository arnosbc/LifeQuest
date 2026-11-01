import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';

/// Hoja de calendario de taco: blanca, con el borde de arriba arrancado.
/// Con [bound] lleva encima la encuadernación y los talones de las hojas
/// ya arrancadas (solo en Hoy: es la firma de la app).
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.bound = false,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 20),
    this.minHeight = 0,
  });

  final Widget child;
  final bool bound;
  final EdgeInsetsGeometry padding;

  /// Alto mínimo de la hoja blanca (Hoy la estira hasta la barra).
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final sheet = ClipPath(
      clipper: const _TornTop(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: q.card,
          border: Border(bottom: BorderSide(color: q.line)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (!bound) return sheet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: q.dark
                      ? const Color(0xFF3A3834)
                      : const Color(0xFF2A2A2A),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              // Talones de las hojas ya arrancadas.
              for (final (height, alpha) in const [(10.0, .8), (7.0, .55)])
                ClipPath(
                  clipper: const _TornBottom(),
                  child: Container(
                    height: height,
                    color: q.card.withValues(alpha: alpha),
                  ),
                ),
            ],
          ),
        ),
        Transform.translate(offset: const Offset(0, -4), child: sheet),
      ],
    );
  }
}

/// Zigzag irregular pero fijo: la misma hoja se ve igual en cada pintado.
const _teeth = <double>[
  6,
  2,
  7,
  0,
  6,
  2,
  8,
  1,
  6,
  0,
  7,
  2,
  8,
  1,
  6,
  0,
  7,
  2,
  6,
];

class _TornTop extends CustomClipper<Path> {
  const _TornTop();

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(0, _teeth.first);
    for (var i = 1; i < _teeth.length; i++) {
      path.lineTo(size.width * i / (_teeth.length - 1), _teeth[i]);
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_TornTop oldClipper) => false;
}

class _TornBottom extends CustomClipper<Path> {
  const _TornBottom();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0);
    for (var i = _teeth.length - 1; i >= 0; i--) {
      final y =
          size.height - _teeth[(i + 5) % _teeth.length] * size.height / 10;
      path.lineTo(size.width * i / (_teeth.length - 1), y);
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornBottom oldClipper) => false;
}

/// Filete discontinuo de la hoja (separa la fecha de la lista).
class PaperRule extends StatelessWidget {
  const PaperRule({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: LayoutBuilder(
      builder: (context, box) => Row(
        children: [
          for (var i = 0; i < box.maxWidth ~/ 7; i++)
            Container(
              width: 4,
              height: 1,
              margin: const EdgeInsets.only(right: 3),
              color: context.lq.line,
            ),
        ],
      ),
    ),
  );
}
