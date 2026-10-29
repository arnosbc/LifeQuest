import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Botón principal de Acceso (Auth.dc.html): 56 px, radio 16, acento con su
/// sombra sólida de 4 px. Cargando no es «desactivado»: mantiene sus colores.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// Mientras carga, el botón ignora toques y muestra un indicador.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final radius = BorderRadius.circular(QRadius.block);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: q.buttonShadow, offset: const Offset(0, 4))],
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: q.accent,
            foregroundColor: q.onAccent,
            disabledBackgroundColor: q.accent,
            disabledForegroundColor: q.onAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
            textStyle: QText.label(q.onAccent).copyWith(fontSize: 17),
          ),
          child: isLoading
              ? Semantics(
                  label: 'Cargando',
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: q.onAccent,
                    ),
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
