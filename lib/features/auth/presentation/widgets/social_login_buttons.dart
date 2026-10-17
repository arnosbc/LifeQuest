import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Separador "O ingresa con" + botones de Google y Apple (aún sin conectar).
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, required this.onNotice});

  final ValueChanged<String> onNotice;

  static ButtonStyle _buttonStyle(BuildContext context) => ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
    foregroundColor: WidgetStatePropertyAll(context.lq.ink),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
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
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  onNotice('El inicio con Google estará disponible pronto.'),
              icon: const Icon(Icons.g_mobiledata, size: 18),
              label: const Text('Google'),
              style: _buttonStyle(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  onNotice('El inicio con Apple estará disponible pronto.'),
              icon: const Icon(Icons.phone_iphone, size: 15),
              label: const Text('Apple'),
              style: _buttonStyle(context),
            ),
          ),
        ],
      ),
    ],
  );
}
