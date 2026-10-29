import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Separador «o continúa con» + botones de Google y Apple (aún sin conectar).
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, required this.onNotice});

  final ValueChanged<String> onNotice;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      foregroundColor: q.text,
      backgroundColor: q.card,
      textStyle: QText.label(q.text).copyWith(fontSize: 15),
      side: BorderSide(color: q.inputBorder, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QRadius.button),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(child: Divider(height: 1, color: q.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'o continúa con',
                  style: QText.body(q.text2).copyWith(fontSize: 13),
                ),
              ),
              Expanded(child: Divider(height: 1, color: q.border)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    onNotice('El inicio con Google estará disponible pronto.'),
                style: style,
                child: const Text('Google'),
              ),
            ),
            const SizedBox(width: QSpace.s),
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    onNotice('El inicio con Apple estará disponible pronto.'),
                style: style,
                child: const Text('Apple'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
