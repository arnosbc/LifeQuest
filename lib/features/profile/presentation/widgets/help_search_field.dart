import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class HelpSearchField extends StatelessWidget {
  const HelpSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onShowAll,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: TextStyle(color: context.lq.ink, fontSize: 10),
    decoration: InputDecoration(
      hintText: 'Buscar en Ayuda',
      hintStyle: TextStyle(color: context.lq.muted, fontSize: 9),
      prefixIcon: Icon(Icons.search, size: 16, color: context.lq.muted),
      suffixIcon: IconButton(
        tooltip: 'Buscar',
        onPressed: onShowAll,
        icon: Icon(
          Icons.keyboard_command_key,
          size: 15,
          color: context.lq.green,
        ),
      ),
      filled: true,
      fillColor: context.lq.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.lq.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.lq.line),
      ),
    ),
  );
}
