import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';

class TermsCheckbox extends StatelessWidget {
  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Checkbox(
        value: value,
        onChanged: (value) => onChanged(value ?? false),
        activeColor: LifeQuestColors.green,
        side: const BorderSide(color: Color(0xFF9AB5A3)),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      const Text(
        'Acepto los ',
        style: TextStyle(color: LifeQuestColors.muted, fontSize: 10),
      ),
      InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Términos y condiciones'),
            content: const Text(
              'Al crear tu cuenta, aceptas usar LifeQuest de forma responsable.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
        child: const Text(
          'términos y condiciones',
          style: TextStyle(
            color: LifeQuestColors.deepGreen,
            fontSize: 10,
            decoration: TextDecoration.underline,
            decorationColor: LifeQuestColors.deepGreen,
          ),
        ),
      ),
    ],
  );
}
