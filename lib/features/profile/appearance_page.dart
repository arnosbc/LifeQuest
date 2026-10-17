import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';
import 'widgets/accent_picker.dart';
import 'widgets/appearance_preview.dart';
import 'widgets/display_preference_tile.dart';
import 'widgets/subpage_header.dart';
import 'widgets/theme_option_card.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  ThemeChoice _theme = ThemeChoice.light;
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
      SubpageHeader(title: 'Apariencia', onBack: widget.onBack),
      const Divider(height: 17, color: LifeQuestColors.line),
      const LifeQuestSectionHeading('TEMA'),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(child: _themeOption(ThemeChoice.light, 'Claro')),
          const SizedBox(width: 6),
          Expanded(child: _themeOption(ThemeChoice.dark, 'Oscuro')),
          const SizedBox(width: 6),
          Expanded(child: _themeOption(ThemeChoice.system, 'Sistema')),
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
      AccentPicker(
        accents: _accents,
        selected: _accent,
        onSelected: (color) => setState(() => _accent = color),
      ),
      const SizedBox(height: 11),
      const LifeQuestSectionHeading('PREFERENCIAS DE VISUALIZACIÓN'),
      const SizedBox(height: 5),
      DisplayPreferenceTile(
        icon: Icons.text_fields,
        title: 'Texto más grande',
        subtitle: 'Aumenta el tamaño del contenido',
        value: _largeText,
        onChanged: (value) => setState(() => _largeText = value),
        activeColor: _accent,
      ),
      DisplayPreferenceTile(
        icon: Icons.motion_photos_off_outlined,
        title: 'Reducir movimiento',
        subtitle: 'Limita animaciones y transiciones',
        value: _reduceMotion,
        onChanged: (value) => setState(() => _reduceMotion = value),
        activeColor: _accent,
      ),
      DisplayPreferenceTile(
        icon: Icons.contrast,
        title: 'Alto contraste',
        subtitle: 'Mejora la distinción entre elementos',
        value: _highContrast,
        onChanged: (value) => setState(() => _highContrast = value),
        activeColor: _accent,
      ),
      const SizedBox(height: 11),
      const LifeQuestSectionHeading('VISTA PREVIA'),
      const SizedBox(height: 5),
      AppearancePreview(
        theme: _theme,
        accent: _accent,
        largeText: _largeText,
        reduceMotion: _reduceMotion,
        highContrast: _highContrast,
      ),
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

  Widget _themeOption(ThemeChoice choice, String label) => ThemeOptionCard(
    choice: choice,
    label: label,
    selected: _theme == choice,
    accent: _accent,
    onTap: () => setState(() => _theme = choice),
  );
}
