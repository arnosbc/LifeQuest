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

/// «Meta del momento» (Main.dc.html, Boss del momento): título y barra de
/// avance con su porcentaje escrito.
class TopGoalCard extends StatelessWidget {
  const TopGoalCard({
    super.key,
    required this.title,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final int progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QuestlyCard(
      onTap: onTap,
      semanticsLabel: 'Meta del momento: $title, $progress % de avance',
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: q.tint,
              borderRadius: BorderRadius.circular(QRadius.control),
            ),
            alignment: Alignment.center,
            child: QIcon(QIcons.flag, color: q.ink, size: 24),
          ),
          const SizedBox(width: QSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: QText.label(q.text)),
                const SizedBox(height: QSpace.s),
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: progress / 100),
                        duration: context.motion(
                          const Duration(milliseconds: 600),
                        ),
                        builder: (_, v, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(QRadius.pill),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 7,
                            color: q.accent,
                            backgroundColor: q.track,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: QSpace.s),
                    Text('$progress%', style: QText.meta(q.text2)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
