import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Fila de Configuración que abre una hoja u otra pantalla.
class SettingLink extends StatelessWidget {
  const SettingLink({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;

  /// Null la deshabilita (p. ej. mientras se guarda).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    // Fila de la hoja: sin caja ni icono decorativo, separada por filete.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: lq.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: lq.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(color: lq.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: lq.muted),
            ],
          ),
        ),
      ),
    );
  }
}
