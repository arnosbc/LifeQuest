import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Página estándar (DESIGN.md v2 §5): Hero con el título y, debajo, la
/// bajada y el contenido. Si la ruta se abrió encima de otra, el Hero lleva
/// «Volver» (el router ya no pone AppBar).
class LifeQuestPage extends StatelessWidget {
  const LifeQuestPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.kicker = '',
    this.icon = QIcons.board,
    this.onAction,
    this.actionLabel,
    this.actionIcon = QIcons.plus,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String kicker;
  final QIcons icon;

  /// Botón del Hero (crear, ajustes…). Necesita [actionLabel].
  final VoidCallback? onAction;
  final String? actionLabel;
  final QIcons actionIcon;

  /// Volver propio; si es null y se puede volver, hace `maybePop`.
  final VoidCallback? onBack;

  /// Otro control junto a la bajada.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        QuestlyHero(
          kicker: kicker,
          heading: title,
          icon: icon,
          onBack:
              onBack ??
              (canPop ? () => Navigator.of(context).maybePop() : null),
          onAction: onAction,
          actionLabel: actionLabel,
          actionIcon: actionIcon,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: QText.body(q.text2).copyWith(fontSize: 14),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: QSpace.l),
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}
