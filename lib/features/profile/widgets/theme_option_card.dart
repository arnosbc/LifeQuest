import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

enum ThemeChoice { light, dark, system }

class ThemeOptionCard extends StatelessWidget {
  const ThemeOptionCard({
    super.key,
    required this.choice,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final ThemeChoice choice;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = choice == ThemeChoice.dark;
    final system = choice == ThemeChoice.system;
    final background = dark ? const Color(0xFF242332) : Colors.white;
    final line = dark ? const Color(0xFF45445A) : const Color(0xFFDCE3E8);
    final bar = dark ? const Color(0xFF7770B9) : const Color(0xFFD9E0E9);

    return InkWell(
      onTap: onTap,
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
                        _bar(system ? line : accent),
                        _bar(bar),
                        _bar(bar),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [_bar(dark ? accent : bar), _bar(bar)],
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
                  color: selected ? accent : LifeQuestColors.muted,
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

  Widget _bar(Color color) => Container(
    height: 3,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}
