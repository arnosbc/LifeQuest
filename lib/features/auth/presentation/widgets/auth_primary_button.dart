import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  /// Mientras carga, el botón ignora toques y muestra un indicador.
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.lq.onDeepGreen,
              ),
            )
          : icon,
      label: Text(label),
      // deepGreen: el blanco sobre `green` no llega al 4.5:1 de WCAG AA.
      style: ElevatedButton.styleFrom(
        backgroundColor: context.lq.deepGreen,
        foregroundColor: context.lq.onDeepGreen,
        // Cargando no es "desactivado": mantiene sus colores.
        disabledBackgroundColor: context.lq.deepGreen,
        disabledForegroundColor: context.lq.onDeepGreen,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
