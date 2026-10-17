import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';

/// Separador "O ingresa con" + botones de Google y Apple (aún sin conectar).
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, required this.onNotice});

  final ValueChanged<String> onNotice;

  static const _buttonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
    foregroundColor: WidgetStatePropertyAll(Color(0xFF293D31)),
    textStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    ),
    side: WidgetStatePropertyAll(BorderSide(color: Color(0xFFD7E7DC))),
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
      const Row(
        children: [
          Expanded(child: Divider(height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'O ingresa con',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
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
              style: _buttonStyle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  onNotice('El inicio con Apple estará disponible pronto.'),
              icon: const Icon(Icons.phone_iphone, size: 15),
              label: const Text('Apple'),
              style: _buttonStyle,
            ),
          ),
        ],
      ),
    ],
  );
}
