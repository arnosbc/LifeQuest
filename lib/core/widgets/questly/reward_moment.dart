import 'dart:async';

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/entities/reward_outcome.dart';
import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_button.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_dialog.dart';

/// Escucha [rewards] y muestra el momento de recompensa (plan A1–A2): una
/// tarjeta arriba con lo ganado y, si sube el nivel o un área, un diálogo.
class RewardMomentListener extends StatefulWidget {
  const RewardMomentListener({
    super.key,
    required this.rewards,
    required this.child,
  });

  final Stream<RewardOutcome> rewards;
  final Widget child;

  @override
  State<RewardMomentListener> createState() => _RewardMomentListenerState();
}

class _RewardMomentListenerState extends State<RewardMomentListener> {
  StreamSubscription<RewardOutcome>? _sub;
  OverlayEntry? _entry;
  Timer? _timer;

  static const _visible = Duration(milliseconds: 2800);

  @override
  void initState() {
    super.initState();
    _sub = widget.rewards.listen(_show);
  }

  void _show(RewardOutcome outcome) {
    if (!mounted) return;
    _hide();
    final entry = OverlayEntry(
      builder: (_) => _RewardCard(outcome: outcome, onTap: _hide),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _entry = entry;
    _timer = Timer(_visible, _hide);
    if (outcome.levelUp || outcome.areaLevelUp) _levelUp(outcome);
  }

  void _hide() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
  }

  void _levelUp(RewardOutcome o) {
    final area = o.areaLevelUp && o.areaName != null
        ? '${o.areaName} sube a nivel ${o.areaLevel}'
        : null;
    showQuestlyDialog<void>(
      context,
      title: o.levelUp ? '¡Subiste al nivel ${o.level}!' : '¡$area!',
      message: [
        if (o.levelUp && area != null) '$area.',
        'Cada tarea que completas te acerca al siguiente.',
      ].join(' '),
      content: const Padding(
        padding: EdgeInsets.only(bottom: QSpace.s),
        child: _Badge(),
      ),
      actions: [
        Builder(
          builder: (context) => QuestlyButton(
            label: 'Seguir',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(color: q.mustardTint, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: QIcon(QIcons.trophy, color: q.mustardInk, size: 36),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.outcome, required this.onTap});

  final RewardOutcome outcome;
  final VoidCallback onTap;

  String get _spoken {
    final o = outcome;
    return [
      if (o.xp > 0) 'Ganaste ${o.xp} XP',
      if (o.coins > 0) '${o.coins} Monedas',
      if (o.constancyChange != 0) '${_signed(o.constancyChange)} de Constancia',
      if (o.streak != null) 'racha de ${o.streak} días',
    ].join(', ');
  }

  static String _signed(int n) => n > 0 ? '+$n' : '−${n.abs()}';

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final o = outcome;
    final top = MediaQuery.paddingOf(context).top + QSpace.s;
    return Positioned(
      top: top,
      left: QSpace.l,
      right: QSpace.l,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: context.motion(QMotion.sheet),
        curve: Curves.easeOutBack,
        builder: (_, t, child) => Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -24 * (1 - t)),
            child: child,
          ),
        ),
        child: Semantics(
          liveRegion: true,
          label: _spoken,
          excludeSemantics: true,
          child: Material(
            color: q.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(QRadius.card),
              side: BorderSide(color: q.border),
            ),
            shadowColor: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(QRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(QSpace.m),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: QSpace.s,
                      runSpacing: QSpace.xs,
                      children: [
                        if (o.xp > 0) _Pill('+${o.xp} XP', q.tint, q.ink),
                        if (o.coins > 0)
                          _Pill(
                            '+${o.coins} Monedas',
                            q.mustardTint,
                            q.mustardInk,
                          ),
                        if (o.constancyChange != 0)
                          _Pill(
                            '${_signed(o.constancyChange)} Constancia',
                            q.coralTint,
                            q.coralInk,
                          ),
                      ],
                    ),
                    if (o.xp > 0 && o.areaName != null) ...[
                      const SizedBox(height: QSpace.s),
                      Text(
                        '+${o.xp} XP en ${o.areaName}',
                        style: QText.body(q.text2).copyWith(fontSize: 13),
                      ),
                    ],
                    if (o.streak != null) ...[
                      const SizedBox(height: QSpace.s),
                      Row(
                        children: [
                          QIcon(QIcons.flame, color: q.coralInk, size: 16),
                          const SizedBox(width: QSpace.xs),
                          Text(
                            o.bestStreak != null && o.bestStreak! > o.streak!
                                ? 'Racha: ${o.streak} días · récord ${o.bestStreak}'
                                : 'Racha: ${o.streak} días · ¡tu récord!',
                            style: QText.label(q.text).copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    if (o.xp > 0 &&
                        o.currentXp != null &&
                        o.xpToNextLevel != null)
                      _LevelBar(outcome: o),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de nivel que se llena desde antes de la recompensa (plan A3).
class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.outcome});

  final RewardOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final o = outcome;
    final next = o.xpToNextLevel!;
    final end = (o.currentXp! / next).clamp(0.0, 1.0);
    final start = o.levelUp
        ? 0.0
        : ((o.currentXp! - o.xp) / next).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: QSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nivel ${o.level} · ${o.currentXp}/$next XP',
            style: QText.number(q.text2, size: 13),
          ),
          const SizedBox(height: QSpace.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: start, end: end),
            duration: context.motion(const Duration(milliseconds: 600)),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(QRadius.pill),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: q.accent,
                backgroundColor: q.track,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.bg, this.fg);

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(QRadius.pill),
    ),
    child: Text(text, style: QText.number(fg, size: 14)),
  );
}
