import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Marca de LifeQuest: montaña con bandera dentro de un círculo lavanda.
class LifeQuestLogo extends StatelessWidget {
  const LifeQuestLogo({super.key, this.size = 96});

  final double size;

  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
      '<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">'
      '<stop offset="0" stop-color="#EEE7FC"/>'
      '<stop offset="1" stop-color="#CDBBF1"/></linearGradient></defs>'
      '<circle cx="50" cy="50" r="46" fill="url(#g)"/>'
      '<path d="M18 76 L38 54 L47 63 L62 42 L84 76Z" fill="#D9CCF6"/>'
      '<path d="M30 76 L46 60 L54 68 L64 56 L76 76Z" fill="#B8A2E6"/>'
      '<path d="M14 72 L36 46 L46 57 L62 32 L86 72" fill="none" '
      'stroke="#4B3594" stroke-width="5" stroke-linecap="round" '
      'stroke-linejoin="round"/>'
      '<path d="M62 32 V12" stroke="#4B3594" stroke-width="3.5" '
      'stroke-linecap="round"/>'
      '<path d="M62 12 L77 17 L62 23Z" fill="#4B3594"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.string(_svg, width: size, height: size),
  );
}

/// «LifeQuest» con «Quest» en lavanda.
class LifeQuestWordmark extends StatelessWidget {
  const LifeQuestWordmark({super.key, this.size = 34, this.onDark = false});

  final double size;

  /// Sobre el paisaje oscuro «Life» va en blanco.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final style = QText.display(
      onDark ? Colors.white : q.text,
    ).copyWith(fontSize: size, letterSpacing: -0.5);
    return Semantics(
      header: true,
      label: 'LifeQuest',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Life', style: style),
            TextSpan(
              text: 'Quest',
              style: style.copyWith(
                color: onDark ? const Color(0xFFD9CCF6) : q.accent,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Paisaje de montañas lavanda (bienvenida, banner de Inicio, avatar).
/// Con [hiker] dibuja la silueta de un caminante en la cima.
class LifeQuestLandscape extends StatelessWidget {
  const LifeQuestLandscape({
    super.key,
    this.hiker = false,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.bottomCenter,
  });

  final bool hiker;
  final BoxFit fit;
  final Alignment alignment;

  static String svg({bool hiker = false}) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" '
      'preserveAspectRatio="xMidYMax slice">'
      '<defs><linearGradient id="s" x1="0" y1="0" x2="0" y2="1">'
      '<stop offset="0" stop-color="#7F62C6"/>'
      '<stop offset=".45" stop-color="#D9C8F2"/>'
      '<stop offset=".7" stop-color="#F4DCEB"/></linearGradient>'
      '<radialGradient id="sun" cx=".5" cy=".5" r=".5">'
      '<stop offset="0" stop-color="#FFF6FB"/>'
      '<stop offset="1" stop-color="#FFF6FB" stop-opacity="0"/>'
      '</radialGradient></defs>'
      '<rect width="400" height="400" fill="url(#s)"/>'
      '<circle cx="250" cy="215" r="90" fill="url(#sun)"/>'
      '<path d="M0 250 L60 205 L110 235 L175 170 L235 225 L290 185 L350 230 '
      'L400 200 V400 H0Z" fill="#CBB9EE"/>'
      '<path d="M0 285 L70 230 L130 265 L205 195 L265 255 L330 215 L400 260 '
      'V400 H0Z" fill="#A68FDC"/>'
      '<path d="M205 195 L190 210 L200 212 L212 204 L222 214 L232 222Z" '
      'fill="#EEE6FB" opacity=".8"/>'
      '<path d="M0 320 L80 275 L150 305 L220 260 L300 300 L400 270 V400 H0Z" '
      'fill="#7C64C0"/>'
      '<path d="M0 360 L90 320 L170 345 L232 312 L300 340 L400 315 V400 H0Z" '
      'fill="#4E3C8C"/>'
      '${hiker ? _hiker : ''}'
      '</svg>';

  // Caminante con mochila de pie sobre la cima del primer plano.
  static const _hiker =
      '<g fill="#2C2152" transform="translate(232 313) scale(.6) translate(-232 -313)">'
      '<circle cx="232" cy="268" r="5"/>'
      '<path d="M226 275 h11 l2 20 h-4 l-1 18 h-3 l-1-14 l-1 14 h-3 l-1-18 '
      'h-3z"/>'
      '<rect x="220" y="276" width="8" height="14" rx="3"/>'
      '</g>';

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.string(
      svg(hiker: hiker),
      fit: fit,
      alignment: alignment,
    ),
  );
}
