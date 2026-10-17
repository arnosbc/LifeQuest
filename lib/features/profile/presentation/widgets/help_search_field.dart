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
    style: const TextStyle(color: LifeQuestColors.ink, fontSize: 10),
    decoration: InputDecoration(
      hintText: 'Buscar en Ayuda',
      hintStyle: const TextStyle(color: LifeQuestColors.muted, fontSize: 9),
      prefixIcon: const Icon(
        Icons.search,
        size: 16,
        color: LifeQuestColors.muted,
      ),
      suffixIcon: IconButton(
        tooltip: 'Buscar',
        onPressed: onShowAll,
        icon: const Icon(
          Icons.keyboard_command_key,
          size: 15,
          color: LifeQuestColors.green,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LifeQuestColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LifeQuestColors.line),
      ),
    ),
  );
}
