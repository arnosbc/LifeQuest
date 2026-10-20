import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/profile_format.dart';

/// Vitalidad, Monedas y tasa de finalización en una sola lista.
class HeroStatusCard extends StatelessWidget {
  const HeroStatusCard({super.key, required this.profile});

  final CharacterProfile profile;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final p = profile;
    final rate = p.completionRate;
    final closed = p.questsCompleted + p.questsFailed;
    final hp = p.hpMax <= 0 ? 0.0 : (p.hpCurrent / p.hpMax).clamp(0.0, 1.0);
    final divider = Divider(height: 1, indent: 72, color: lq.line);

    return LifeQuestSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _StatusRow(
            icon: p.isWeakened
                ? Icons.heart_broken_outlined
                : Icons.favorite_outline_rounded,
            label: 'Vitalidad (HP)',
            value: '${p.hpCurrent} / ${p.hpMax}',
            detail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: hp,
                  minHeight: 6,
                  // Rosa solo como relleno: nombra la pérdida, sin alarmar.
                  color: p.isWeakened ? lq.warning : lq.green,
                  backgroundColor: lq.softGreen,
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  semanticsLabel: 'Vitalidad',
                  semanticsValue: '${(hp * 100).round()} %',
                ),
                if (p.isWeakened) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Vitalidad baja: ganas un 10 % menos hasta recuperarte.',
                    style: TextStyle(color: lq.muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          divider,
          _StatusRow(
            icon: Icons.toll_outlined,
            label: 'Monedas',
            value: formatNumber(p.coins),
            detail: _detail(context, 'Para canjear en el Marketplace'),
          ),
          divider,
          _StatusRow(
            icon: Icons.task_alt_rounded,
            label: 'Tasa de finalización',
            value: rate == null ? null : '${(rate * 100).round()} %',
            detail: _detail(
              context,
              rate == null
                  ? 'Tu bitácora está en blanco: tu primera misión la estrena.'
                  : '${p.questsCompleted} de $closed misiones cumplidas',
            ),
          ),
        ],
      ),
    );
  }

  static Widget _detail(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(text, style: TextStyle(color: context.lq.muted, fontSize: 13)),
  );
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.detail,
    this.value,
  });

  final IconData icon;
  final String label;
  final Widget detail;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LifeQuestIconTile(icon, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: lq.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (value != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        value!,
                        style: TextStyle(
                          color: lq.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
                detail,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
