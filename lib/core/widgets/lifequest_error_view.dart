import 'package:flutter/material.dart';

import 'package:proyecto_movil/app/config/theme.dart';

/// Primera carga fallida: el mensaje y un botón para reintentar.
class LifeQuestErrorView extends StatelessWidget {
  const LifeQuestErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 40, color: context.lq.muted),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.lq.ink, fontSize: 15),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
          ),
        ],
      ),
    ),
  );
}
