import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/level_rank.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_format.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/how_it_works_sheet.dart';

/// «Tu progreso» (Main.dc.html): insignia de nivel con su rango, barra de XP
/// en 10 segmentos y Constancia · Monedas · Racha. Tocar abre el Perfil.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.dashboard,
    required this.onOpenProfile,
    this.onExplain,
  });

  final HomeDashboard dashboard;
  final VoidCallback onOpenProfile;

  /// Abre «¿Cómo funciona?» al tocar la barra o una cifra.
  final ValueChanged<HowItWorks>? onExplain;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final d = dashboard;
    final xpLeft = (d.xpToNextLevel - d.currentXp).clamp(0, d.xpToNextLevel);
    final filled = d.xpToNextLevel == 0
        ? 0
        : (d.currentXp * 10 ~/ d.xpToNextLevel).clamp(0, 10);
    return QuestlyCard(
      onTap: onOpenProfile,
      semanticsLabel:
          '${levelRank(d.level)}, nivel ${d.level}. Te faltan $xpLeft XP para '
          'el nivel ${d.level + 1}. Abrir perfil',
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LevelBadge(level: d.level),
              const SizedBox(width: QSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${levelRank(d.level)} · Nivel ${d.level}',
                      style: QText.title3(q.text).copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Te faltan ${HomeFormat.number(xpLeft)} XP para el '
                      'nivel ${d.level + 1}',
                      style: QText.body(q.text2).copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text('Perfil', style: QText.label(q.ink).copyWith(fontSize: 13)),
              Icon(Icons.chevron_right_rounded, size: 18, color: q.ink),
            ],
          ),
          const SizedBox(height: QSpace.m),
          Semantics(
            container: true,
            button: true,
            label:
                'Experiencia ${d.currentXp} de ${d.xpToNextLevel}. ¿Cómo funciona?',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onExplain?.call(HowItWorks.xp),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    for (var i = 0; i < 10; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        child: AnimatedContainer(
                          duration: context.motion(QMotion.sheet),
                          height: 10,
                          decoration: BoxDecoration(
                            color: i < filled ? q.accent : q.track,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: QSpace.xs),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: QIcons.leaf,
                  value: '${d.hpCurrent}',
                  label:
                      'Constancia ${d.hpCurrent} de ${d.hpMax}. ¿Cómo funciona?',
                  bg: q.coralTint,
                  fg: q.coralInk,
                  onTap: () => onExplain?.call(HowItWorks.constancy),
                ),
              ),
              const SizedBox(width: QSpace.s),
              Expanded(
                child: _Stat(
                  icon: QIcons.coin,
                  value: HomeFormat.number(d.coins),
                  label: '${d.coins} Monedas. ¿Cómo funcionan?',
                  bg: q.mustardTint,
                  fg: q.mustardInk,
                  onTap: () => onExplain?.call(HowItWorks.coins),
                ),
              ),
              const SizedBox(width: QSpace.s),
              Expanded(
                child: _Stat(
                  icon: QIcons.flame,
                  value: '${d.streakDays} d',
                  label: 'Racha de ${d.streakDays} días',
                  bg: q.bg,
                  fg: q.text,
                ),
              ),
            ],
          ),
          if (d.isWeakened) ...[
            const SizedBox(height: QSpace.m),
            Container(
              padding: const EdgeInsets.all(QSpace.m),
              decoration: BoxDecoration(
                color: q.coralTint,
                borderRadius: BorderRadius.circular(QRadius.control),
              ),
              child: Text(
                'Tu Constancia está baja por ahora: ganas un 25 % menos de XP '
                'hasta recuperarla. Las Monedas no cambian. Un hábito bueno '
                'al día la sube.',
                style: QText.body(q.coralInk).copyWith(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return ExcludeSemantics(
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: q.mustardTint,
          shape: BoxShape.circle,
          border: Border.all(color: QColors.mustard, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          '$level',
          style: QText.title3(q.mustardInk).copyWith(fontSize: 20),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
    this.onTap,
  });

  final QIcons icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    button: onTap != null,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: QSize.minTap),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(QRadius.control),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QIcon(icon, color: fg, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: QText.number(fg, size: 14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
