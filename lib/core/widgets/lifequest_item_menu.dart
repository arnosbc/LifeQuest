import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/widgets/confirm_dialog.dart';

/// Menú «⋯» de un elemento: renombrar (pide el nombre nuevo) y borrar (pide
/// confirmación). Solo llama a los callbacks si el usuario acepta.
class LifeQuestItemMenu extends StatelessWidget {
  const LifeQuestItemMenu({
    super.key,
    required this.name,
    required this.onRename,
    required this.onDelete,
    this.enabled = true,
    this.maxLength = 200,
    this.deleteMessage,
  });

  final String name;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;
  final bool enabled;
  final int maxLength;

  /// Qué pasa al borrar, si no es obvio.
  final String? deleteMessage;

  Future<void> _onSelected(BuildContext context, bool delete) async {
    if (delete) {
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
  Widget build(BuildContext context) => PopupMenuButton<bool>(
    enabled: enabled,
    tooltip: 'Opciones de «$name»',
    icon: Icon(Icons.more_vert, color: context.lq.muted, size: 20),
    onSelected: (delete) => _onSelected(context, delete),
    itemBuilder: (_) => const [
      PopupMenuItem(value: false, child: Text('Renombrar')),
      PopupMenuItem(value: true, child: Text('Borrar')),
    ],
  );
}
