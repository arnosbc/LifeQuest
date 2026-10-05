import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

enum _ThemeChoice { light, dark, system }

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  _ThemeChoice _theme = _ThemeChoice.light;
  Color _accent = const Color(0xFF12A34A);
  bool _largeText = false;
  bool _reduceMotion = false;
  bool _highContrast = false;

  static const _accents = [
    Color(0xFF12A34A),
    Color(0xFF078B43),
    Color(0xFF00A05A),
    Color(0xFF07964D),
    Color(0xFF008F54),
    Color(0xFF008F43),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 9, 14, 22),
    children: [
      _header(),
      const Divider(height: 17, color: LifeQuestColors.line),
      const LifeQuestSectionHeading('TEMA'),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(child: _themeOption(_ThemeChoice.light, 'Claro')),
          const SizedBox(width: 6),
          Expanded(child: _themeOption(_ThemeChoice.dark, 'Oscuro')),
          const SizedBox(width: 6),
          Expanded(child: _themeOption(_ThemeChoice.system, 'Sistema')),
        ],
      ),
      const SizedBox(height: 11),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'COLOR DE ACENTO',
            style: TextStyle(
              color: LifeQuestColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            _accentName,
            style: TextStyle(
              color: _accent,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      LifeQuestSurface(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final color in _accents) _accentDot(color)],
        ),
      ),
      const SizedBox(height: 11),
      const LifeQuestSectionHeading('PREFERENCIAS DE VISUALIZACIÓN'),
      const SizedBox(height: 5),
      _preferenceTile(
        Icons.text_fields,
        'Texto más grande',
        'Aumenta el tamaño del contenido',
        _largeText,
        (value) => setState(() => _largeText = value),
      ),
      _preferenceTile(
        Icons.motion_photos_off_outlined,
        'Reducir movimiento',
        'Limita animaciones y transiciones',
        _reduceMotion,
        (value) => setState(() => _reduceMotion = value),
      ),
      _preferenceTile(
        Icons.contrast,
        'Alto contraste',
        'Mejora la distinción entre elementos',
        _highContrast,
        (value) => setState(() => _highContrast = value),
      ),
      const SizedBox(height: 11),
      const LifeQuestSectionHeading('VISTA PREVIA'),
      const SizedBox(height: 5),
      _preview(),
      const SizedBox(height: 8),
      LifeQuestSurface(
        color: const Color(0xFFEAF8EE),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: _accent, size: 13),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'La vista previa se actualiza al instante con tus preferencias.',
                style: TextStyle(color: LifeQuestColors.deepGreen, fontSize: 8),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  String get _accentName => switch (_accents.indexOf(_accent)) {
    0 => 'Verde',
    1 => 'Bosque',
    2 => 'Menta',
    3 => 'Esmeralda',
    4 => 'Jade',
    _ => 'Hoja',
  };

  Widget _header() => Row(
    children: [
      InkWell(
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: LifeQuestColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.chevron_left,
            color: LifeQuestColors.muted,
            size: 18,
          ),
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Apariencia',
        style: TextStyle(
          color: LifeQuestColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _themeOption(_ThemeChoice choice, String label) {
    final selected = _theme == choice;
    final dark = choice == _ThemeChoice.dark;
    final system = choice == _ThemeChoice.system;
    final background = dark ? const Color(0xFF242332) : Colors.white;
    final line = dark ? const Color(0xFF45445A) : const Color(0xFFDCE3E8);
    final bar = dark ? const Color(0xFF7770B9) : const Color(0xFFD9E0E9);

    return InkWell(
      onTap: () => setState(() => _theme = choice),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? LifeQuestColors.green : LifeQuestColors.line,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              height: 39,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: background,
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: system ? line : _accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: dark ? _accent : bar,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? _accent : LifeQuestColors.muted,
                  size: 11,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _accentDot(Color color) {
    final selected = color == _accent;
    return InkWell(
      onTap: () => setState(() => _accent = color),
      customBorder: const CircleBorder(),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _preferenceTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: LifeQuestSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          LifeQuestIconTile(icon, size: 24),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: LifeQuestColors.muted,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    ),
  );

  Widget _preview() {
    final background = _theme == _ThemeChoice.dark
        ? const Color(0xFF242332)
        : Colors.white;
    final textColor = _theme == _ThemeChoice.dark
        ? Colors.white
        : LifeQuestColors.ink;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: _highContrast ? _accent : LifeQuestColors.line,
            width: _highContrast ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 23,
              height: 23,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  color: _accent,
                  fontSize: _largeText ? 10 : 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lectura cómoda y clara',
                    style: TextStyle(
                      color: textColor,
                      fontSize: _largeText ? 10 : 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _highContrast
                        ? 'Alto contraste · Texto ampliado'
                        : 'Contraste alto · Tamaño estándar',
                    style: TextStyle(color: _accent, fontSize: 7),
                  ),
                ],
              ),
            ),
            if (_reduceMotion)
              Icon(Icons.pause_circle_outline, color: _accent, size: 14),
          ],
        ),
      ),
    );
  }
}
