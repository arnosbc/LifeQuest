import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Abre una hoja inferior con tirador, título y cierre visible. Devuelve lo
/// que se pase a `Navigator.pop`.
Future<T?> showQuestlySheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  final q = context.q;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: q.sheetScrim,
    barrierLabel: 'Cerrar',
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    sheetAnimationStyle: AnimationStyle(
      duration: context.motion(QMotion.sheet),
      reverseDuration: context.motion(QMotion.fade),
    ),
    builder: (_) => QuestlySheet(title: title, child: child),
  );
}

/// Contenido de la hoja (DESIGN.md §5).
class QuestlySheet extends StatelessWidget {
  const QuestlySheet({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      decoration: BoxDecoration(
        color: q.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(QRadius.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        10,
        22,
        26 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: q.border,
                borderRadius: BorderRadius.circular(QRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: QText.title2(q.text)),
                ),
              ),
              QuestlyCloseButton(onTap: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}

/// Botón redondo «Cerrar» de 44 × 44 de hojas y diálogos.
class QuestlyCloseButton extends StatelessWidget {
  const QuestlyCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      label: 'Cerrar',
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: 'Cerrar',
        excludeFromSemantics: true,
        child: Material(
          color: q.bg,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: QSize.minTap,
              child: Center(
                child: QIcon(
                  QIcons.close,
                  color: q.text,
                  size: 18,
                  strokeWidth: 2.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
