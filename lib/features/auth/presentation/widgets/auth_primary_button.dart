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
    height: 44,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: LifeQuestColors.green,
        foregroundColor: Colors.white,
        elevation: 7,
        shadowColor: LifeQuestColors.green.withValues(alpha: 0.24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
