import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Separador "O ingresa con" + botón de Google.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, required this.onGoogle});

  final VoidCallback onGoogle;

  static ButtonStyle _buttonStyle(BuildContext context) => ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.fromHeight(44)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
    foregroundColor: WidgetStatePropertyAll(context.lq.ink),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    ),
    side: WidgetStatePropertyAll(BorderSide(color: context.lq.outline)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(9)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Divider(height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'O ingresa con',
              style: TextStyle(color: context.lq.muted, fontSize: 9),
            ),
          ),
          Expanded(child: Divider(height: 1)),
        ],
      ),
      const SizedBox(height: 9),
      OutlinedButton.icon(
        onPressed: onGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 22),
        label: const Text('Continuar con Google'),
        style: _buttonStyle(context),
      ),
    ],
  );
}
