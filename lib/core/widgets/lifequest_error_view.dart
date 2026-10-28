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
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.lq.ink),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
