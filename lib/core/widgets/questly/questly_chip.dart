import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Filtro de lista: el activo va con fondo fuerte, el resto con borde.
class QuestlyFilterChip extends StatelessWidget {
  const QuestlyFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? q.strong : q.card,
        shape: StadiumBorder(
          side: selected
              ? BorderSide.none
              : BorderSide(color: q.inputBorder, width: 1.5),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: QSize.minTap,
              minWidth: QSize.minTap,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: QText.label(
                    selected ? q.onStrong : q.text,
                  ).copyWith(fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de Área (skill): tinte y tinta del tema.
class QuestlyTagChip extends StatelessWidget {
  const QuestlyTagChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: q.tint,
        borderRadius: BorderRadius.circular(QRadius.pill),
      ),
      child: Text(label, style: QText.label(q.ink).copyWith(fontSize: 12)),
    );
  }
}

enum QuestlyPriority { high, medium, low }

/// Prioridad con símbolo + texto: el color nunca va solo.
class QuestlyPriorityChip extends StatelessWidget {
  const QuestlyPriorityChip(this.priority, {super.key});

  final QuestlyPriority priority;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final (String text, Color bg, Color fg) = switch (priority) {
      QuestlyPriority.high => ('▲ Alta', q.coralTint, q.coralInk),
      QuestlyPriority.medium => ('● Media', q.mustardTint, q.mustardInk),
      QuestlyPriority.low => ('▼ Baja', q.track, q.text3),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QRadius.chip),
      ),
      child: Text(
        text,
        semanticsLabel: 'Prioridad ${text.substring(2).toLowerCase()}',
        style: QText.label(fg).copyWith(fontSize: 12),
      ),
    );
  }
}
