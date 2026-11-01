import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/paper_sheet.dart';

class LifeQuestPage extends StatelessWidget {
  const LifeQuestPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
    this.numeral,
    this.numeralLabel,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  /// La cifra de la pantalla, en grande, como el número de una hoja.
  final String? numeral;
  final String? numeralLabel;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.lq.ink,
                    fontSize: 32,
                    height: 1.1,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
        child: Text(
          subtitle,
          style: TextStyle(color: context.lq.muted, fontSize: 15),
        ),
      ),
      PaperSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (numeral != null) ...[
              Semantics(
                label: '$numeral ${numeralLabel ?? ''}',
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      numeral!,
                      style: QText.numeral(context.lq.ink, size: 88),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          numeralLabel ?? '',
                          style: QText.title3(context.lq.muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const PaperRule(),
              const SizedBox(height: 8),
            ],
            ...children,
          ],
        ),
      ),
    ],
  );
}
