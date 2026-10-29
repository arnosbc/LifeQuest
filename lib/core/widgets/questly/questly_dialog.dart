import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_sheet.dart';

/// Diálogo con título, cierre visible y foco atrapado (la ruta es modal).
/// [actions] suelen ser `QuestlyButton`s; cada una hace su `Navigator.pop`.
Future<T?> showQuestlyDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  List<Widget> actions = const [],
}) {
  final q = context.q;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: q.dialogScrim,
    transitionDuration: context.motion(QMotion.fade),
    transitionBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    pageBuilder: (context, _, _) => QuestlyDialog(
      title: title,
      message: message,
      content: content,
      actions: actions,
    ),
  );
}

class QuestlyDialog extends StatelessWidget {
  const QuestlyDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(QSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: q.card,
              borderRadius: BorderRadius.circular(QRadius.sheet),
              child: Padding(
                padding: const EdgeInsets.all(QSpace.gutter),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(title, style: QText.title2(q.text)),
                          ),
                        ),
                        QuestlyCloseButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    if (message != null) ...[
                      const SizedBox(height: QSpace.m),
                      Text(message!, style: QText.body(q.text2)),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: QSpace.m),
                      Flexible(child: SingleChildScrollView(child: content)),
                    ],
                    for (final action in actions) ...[
                      const SizedBox(height: QSpace.m),
                      action,
                    ],
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
