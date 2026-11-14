import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Tarjeta-enlace del Inicio (Main.dc.html: Taverna y Brain Dump): icono en
/// tinte, kicker en mayúsculas, título y una línea de apoyo.
class HomeLinkCard extends StatelessWidget {
  const HomeLinkCard({
    super.key,
    required this.icon,
    required this.kicker,
    required this.title,
    required this.detail,
    required this.tint,
    required this.ink,
    required this.onTap,
  });

  final QIcons icon;
  final String kicker;
  final String title;
  final String detail;
  final Color tint;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QuestlyCard(
      onTap: onTap,
      semanticsLabel: '$kicker. $title. $detail',
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(QRadius.block),
            ),
            alignment: Alignment.center,
            child: QIcon(icon, color: ink, size: 26),
          ),
          const SizedBox(width: QSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kicker.toUpperCase(), style: QText.meta(ink)),
                const SizedBox(height: 3),
                Text(title, style: QText.label(q.text).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: QText.body(q.text2).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: q.text2),
        ],
      ),
    );
  }
}

/// Banner de la meta actual sobre el camino, como el «Etapa · Sección» de
/// Duolingo. Sin meta, invita a crear una.
class GoalBanner extends StatelessWidget {
  const GoalBanner({
    super.key,
    required this.title,
    required this.progress,
    required this.onTap,
  });

  /// Null: aún no hay metas activas.
  final String? title;
  final int progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final has = title != null;
    final onAccent = q.onAccent;
    return QuestlyPressable(
      radius: QRadius.card,
      onTap: onTap,
      semanticsLabel: has
          ? 'Meta actual: $title, $progress % de avance. Ver metas'
          : 'Aún no tienes metas. Crear una meta',
      decoration: BoxDecoration(
        color: q.accent,
        borderRadius: BorderRadius.circular(QRadius.card),
        boxShadow: [
          BoxShadow(color: q.buttonShadow, offset: const Offset(0, 5)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      has ? 'META ACTUAL · $progress %' : 'TU PRÓXIMA META',
                      style: QText.meta(onAccent.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title ?? 'Crea una meta y dale rumbo a tu camino',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: QText.title3(onAccent),
                    ),
                    if (has) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(QRadius.action),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          color: onAccent,
                          backgroundColor: onAccent.withValues(alpha: 0.25),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Separador y acceso, como el cuaderno del banner de Duolingo.
            Container(width: 2, color: q.buttonShadow),
            SizedBox(
              width: 64,
              child: Center(
                child: QIcon(
                  has ? QIcons.flag : QIcons.plus,
                  color: onAccent,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
