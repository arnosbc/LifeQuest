import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_pressable.dart';

enum QuestlyButtonVariant { primary, secondary, tonal, destructive, text }

/// Botón del sistema (SistemaDiseno.dc.html). Desactivado ([onPressed] null)
/// se ve gris y muestra [disabledReason]: el texto explica por qué.
class QuestlyButton extends StatelessWidget {
  const QuestlyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = QuestlyButtonVariant.primary,
    this.disabledReason,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final QuestlyButtonVariant variant;
  final String? disabledReason;
  final QIcons? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final enabled = onPressed != null;
    final v = enabled ? variant : null;
    final (Color bg, Color fg, Color? border, Color? shadow) = switch (v) {
      QuestlyButtonVariant.primary => (
        q.accent,
        q.onAccent,
        null,
        q.buttonShadow,
      ),
      QuestlyButtonVariant.secondary => (q.card, q.text, q.inputBorder, null),
      QuestlyButtonVariant.tonal => (q.tint, q.ink, q.tonalBorder, null),
      QuestlyButtonVariant.destructive => (
        q.destructive,
        q.onDestructive,
        null,
        q.destructiveShadow,
      ),
      QuestlyButtonVariant.text => (Colors.transparent, q.ink, null, null),
      null => (q.disabled, q.onDestructive, null, null),
    };
    final height = switch (variant) {
      QuestlyButtonVariant.tonal => 48.0,
      QuestlyButtonVariant.text => QSize.minTap,
      _ => QSize.buttonPrimary,
    };
    final fontSize = switch (variant) {
      QuestlyButtonVariant.tonal => 15.0,
      QuestlyButtonVariant.text => 14.0,
      _ => 16.0,
    };
    final text = enabled ? label : (disabledReason ?? label);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          QIcon(icon!, color: fg, size: 18, strokeWidth: 2.2),
          const SizedBox(width: QSpace.s),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: QText.label(fg).copyWith(fontSize: fontSize),
          ),
        ),
      ],
    );
    return QuestlyPressable(
      onTap: onPressed,
      radius: QRadius.button,
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: expand ? double.infinity : QSize.minTap,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.l,
        vertical: QSpace.s,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(QRadius.button),
        border: border == null ? null : Border.all(color: border, width: 1.5),
        boxShadow: shadow == null ? null : qSolidShadow(shadow),
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: content),
    );
  }
}
