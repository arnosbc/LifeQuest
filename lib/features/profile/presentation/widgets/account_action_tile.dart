import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Fila de la lista de Cuenta. Va dentro de una superficie compartida.
class AccountActionTile extends StatelessWidget {
  const AccountActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// Ajuste actual, mostrado antes de la flecha (p. ej. «Oscuro»).
  final String? value;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: lq.deepGreen, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: lq.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    value!,
                    style: TextStyle(color: lq.muted, fontSize: 14),
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
