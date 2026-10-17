import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      // deepGreen: el blanco sobre `green` no llega al 4.5:1 de WCAG AA.
      style: ElevatedButton.styleFrom(
        backgroundColor: context.lq.deepGreen,
        foregroundColor: context.lq.onDeepGreen,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
