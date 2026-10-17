import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/theme_option_card.dart';

class AppearancePreview extends StatelessWidget {
  const AppearancePreview({
    super.key,
    required this.theme,
    required this.accent,
    required this.largeText,
    required this.reduceMotion,
    required this.highContrast,
  });

  final ThemeChoice theme;
  final Color accent;
  final bool largeText;
  final bool reduceMotion;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final background = theme == ThemeChoice.dark
        ? const Color(0xFF242332)
        : Colors.white;
    final textColor = theme == ThemeChoice.dark
        ? Colors.white
        : LifeQuestColors.ink;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: highContrast ? accent : LifeQuestColors.line,
            width: highContrast ? 2 : 1,
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
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Aa',
                style: TextStyle(
                  color: accent,
                  fontSize: largeText ? 10 : 8,
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
                      fontSize: largeText ? 10 : 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    highContrast
                        ? 'Alto contraste · Texto ampliado'
                        : 'Contraste alto · Tamaño estándar',
                    style: TextStyle(color: accent, fontSize: 7),
                  ),
                ],
              ),
            ),
            if (reduceMotion)
              Icon(Icons.pause_circle_outline, color: accent, size: 14),
          ],
        ),
      ),
    );
  }
}
