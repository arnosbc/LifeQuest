import 'package:flutter/material.dart';

/// Pide confirmación antes de gastar Monedas o de una acción que no se
/// deshace. Devuelve true solo si el usuario aceptó.
Future<bool> confirmLifeQuest(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

/// Pide un texto corto (p. ej. la misión de un NPC). Devuelve null si se
/// cancela o queda vacío.
Future<String?> askLifeQuestText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirmLabel,
  String initial = '',
  int maxLength = 200,
}) async {
  final controller = TextEditingController(text: initial);
  final text = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  // Sin dispose: el diálogo aún se dibuja durante su animación de cierre.
  final trimmed = text?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
