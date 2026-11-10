import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/widgets/confirm_dialog.dart';

/// Menú «⋯» de un elemento: [onEdit] opcional (abre su propia hoja),
/// renombrar (pide el nombre nuevo) y borrar (pide confirmación). Solo llama
/// a los callbacks si el usuario acepta.
class LifeQuestItemMenu extends StatelessWidget {
  const LifeQuestItemMenu({
    super.key,
    required this.name,
    required this.onRename,
    required this.onDelete,
    this.enabled = true,
    this.maxLength = 200,
    this.deleteMessage,
    this.onEdit,
    this.editLabel = 'Editar',
    this.onDone,
    this.onResources,
  });

  /// Abre la hoja de recursos (enlaces, fotos, PDF, notas).
  final VoidCallback? onResources;

  /// «Ya la hice»: marcar como hecho sin pasar por Foco.
  final VoidCallback? onDone;

  final String name;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  final bool enabled;
  final int maxLength;

  /// Qué pasa al borrar, si no es obvio.
  final String? deleteMessage;
  final VoidCallback? onEdit;
  final String editLabel;

  Future<void> _onSelected(BuildContext context, _Action action) async {
    if (action == _Action.edit) return onEdit?.call();
    if (action == _Action.done) return onDone?.call();
    if (action == _Action.resources) return onResources?.call();
    if (action == _Action.delete) {
      if (await confirmLifeQuest(
        context,
        title: 'Borrar «$name»',
        message: deleteMessage ?? 'No se puede deshacer.',
        confirmLabel: 'Borrar',
      )) {
        onDelete();
      }
      return;
    }
    final renamed = await askLifeQuestText(
      context,
      title: 'Renombrar',
      label: 'Nombre',
      confirmLabel: 'Guardar',
      initial: name,
      maxLength: maxLength,
    );
    if (renamed != null && renamed != name) onRename(renamed);
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<_Action>(
    enabled: enabled,
    tooltip: 'Opciones de «$name»',
    icon: Icon(Icons.more_vert, color: context.lq.muted, size: 20),
    onSelected: (action) => _onSelected(context, action),
    itemBuilder: (_) => [
      if (onDone != null)
        const PopupMenuItem(value: _Action.done, child: Text('Ya la hice')),
      if (onEdit != null)
        PopupMenuItem(value: _Action.edit, child: Text(editLabel)),
      if (onResources != null)
        const PopupMenuItem(value: _Action.resources, child: Text('Recursos')),
      const PopupMenuItem(value: _Action.rename, child: Text('Renombrar')),
      const PopupMenuItem(value: _Action.delete, child: Text('Borrar')),
    ],
  );
}

enum _Action { done, edit, resources, rename, delete }
