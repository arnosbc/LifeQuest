import 'dart:async';

import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Muestra un toast 2,2 s (DESIGN.md §5). Uno a la vez: el nuevo reemplaza
/// al anterior. Con [onUndo] lleva el botón «Deshacer».
void showQuestlyToast(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
}) {
  _current?.dismiss();
  final overlay = Overlay.of(context, rootOverlay: true);
  final toast = _Toast();
  toast.entry = OverlayEntry(
    builder: (_) => QuestlyToast(
      message: message,
      onUndo: onUndo == null
          ? null
          : () {
              toast.dismiss();
              onUndo();
            },
    ),
  );
  overlay.insert(toast.entry);
  toast.timer = Timer(questlyToastDuration, toast.dismiss);
  _current = toast;
}

const questlyToastDuration = Duration(milliseconds: 2200);

_Toast? _current;

class _Toast {
  late final OverlayEntry entry;
  Timer? timer;
  bool _gone = false;

  void dismiss() {
    if (_gone) return;
    _gone = true;
    timer?.cancel();
    entry.remove();
    if (_current == this) _current = null;
  }
}

/// Aviso flotante que se anuncia al lector de pantalla (role=status).
class QuestlyToast extends StatelessWidget {
  const QuestlyToast({super.key, required this.message, this.onUndo});

  final String message;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Positioned(
      left: QSpace.gutter,
      right: QSpace.gutter,
      bottom: 96 + MediaQuery.paddingOf(context).bottom,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: context.motion(QMotion.sheet),
        curve: Curves.easeOut,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 48 * (1 - t)),
            child: child,
          ),
        ),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Material(
            color: q.strong,
            borderRadius: BorderRadius.circular(QRadius.button),
            elevation: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(QRadius.button),
                boxShadow: [
                  BoxShadow(
                    color: q.toastShadow,
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  onUndo == null ? 12 : 0,
                  onUndo == null ? 14 : 4,
                  onUndo == null ? 12 : 0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: QText.body(q.onStrong).copyWith(fontSize: 14),
                      ),
                    ),
                    if (onUndo != null)
                      TextButton(
                        onPressed: onUndo,
                        style: TextButton.styleFrom(
                          foregroundColor: q.toastAction,
                          minimumSize: const Size(QSize.minTap, QSize.minTap),
                          textStyle: QText.label(q.toastAction),
                        ),
                        child: const Text('Deshacer'),
                      ),
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
