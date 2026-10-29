// Iconos de trazo del diseño (Hero.dc.html y la barra de Main.dc.html), en
// una cuadrícula de 24 × 24. Se pintan con [QIcon].

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum QIcons {
  sword(
    '<path d="M14.5 17.5L3 6V3h3l11.5 11.5M13 19l6-6M16 16l4 4M19 21l2-2"/>',
  ),
  home('<path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>'),
  board('<path d="M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z"/>'),
  stage(
    '<rect x="3" y="3" width="7" height="7" rx="1.5"/>'
    '<rect x="14" y="3" width="7" height="7" rx="1.5"/>'
    '<rect x="3" y="14" width="7" height="7" rx="1.5"/>'
    '<rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  ),
  habits(
    '<path d="M4 12a8 8 0 0 1 14-5.3L20 9M20 4v5h-5M20 12a8 8 0 0 1-14 5.3'
    'L4 15M4 20v-5h5"/>',
  ),
  profile('<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>'),
  leaf('<path d="M5 19C5 10 11 4 20 4c0 9-6 15-15 15zM5 19l8-8"/>'),
  user('<path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0"/>'),
  book(
    '<path d="M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 '
    '3-3h11"/>',
  ),
  gear(
    '<path d="M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6zM12 2v3M12 19v3M2 12h3M19 '
    '12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>',
  ),
  mug(
    '<path d="M5 8h11v8a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4zM16 10h2a2 2 0 0 1 0 '
    '4h-2M8 3v2M12 3v2"/>',
  ),
  flame(
    '<path d="M12 2c1 4 6 6 6 12a6 6 0 0 1-12 0c0-3 1.5-4.5 3-6 0 2.5 1 4 '
    '2.5 4C11.5 9 10 5 12 2z"/>',
  ),
  coin(
    '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v10M9 10h4.5a1.5 1.5 '
    '0 0 1 0 3h-3a1.5 1.5 0 0 0 0 3H15"/>',
  ),
  crown('<path d="M3 18h18M4 18L3 7l5 4 4-7 4 7 5-4-1 11"/>'),
  star(
    '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 '
    '9.5l6.1-.9z"/>',
  ),
  boss(
    '<path d="M6 9L4 3l5 3M18 9l2-6-5 3M5 11c0-5 14-5 14 0v8c0 2-2 3-4 2l-3-2'
    '-3 2c-2 1-4 0-4-2z"/>',
  ),
  inbox(
    '<path d="M3 13l3-8h12l3 8v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1zM3 13h5l1 3h6'
    'l1-3h5"/>',
  ),
  calendar('<path d="M4 6h16v14H4zM4 10h16M8 3v4M16 3v4"/>'),
  archive('<path d="M3 4h18v4H3zM5 8v12h14V8M10 12h4"/>'),
  plus('<path d="M12 5v14M5 12h14"/>'),
  edit('<path d="M4 20h4L19 9l-4-4L4 16zM14 6l4 4"/>'),
  bell('<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 21h4"/>'),
  back('<path d="M15 6l-6 6 6 6"/>'),
  close('<path d="M6 6l12 12M18 6L6 18"/>');

  const QIcons(this.svg);

  final String svg;
}

/// Icono decorativo de trazo: el nombre accesible lo pone el botón que lo usa.
class QIcon extends StatelessWidget {
  const QIcon(
    this.icon, {
    super.key,
    required this.color,
    this.size = 20,
    this.strokeWidth = 2,
  });

  final QIcons icon;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000" stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round">${icon.svg}</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    ),
  );
}
