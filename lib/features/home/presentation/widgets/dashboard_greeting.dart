import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.userName,
    required this.onOpenProfile,
    this.now,
  });

  final String userName;
  final VoidCallback onOpenProfile;
  final DateTime? now;

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final date = now ?? DateTime.now();
    final greeting = date.hour < 12
        ? 'Buenos días'
        : date.hour < 19
        ? 'Buenas tardes'
        : 'Buenas noches';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_weekdays[date.weekday - 1]}, ${date.day} de '
                '${_months[date.month - 1]}',
                style: TextStyle(
                  color: context.lq.deepGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$greeting, $userName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.lq.ink,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tu siguiente avance está listo.',
                style: TextStyle(color: context.lq.muted, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Notificaciones',
          onPressed: () =>
              showLifeQuestMessage(context, 'No tienes notificaciones nuevas.'),
          icon: const Icon(Icons.notifications_none_rounded, size: 22),
          style: IconButton.styleFrom(
            backgroundColor: context.lq.surface,
            foregroundColor: context.lq.ink,
            side: BorderSide(color: context.lq.line),
            minimumSize: const Size(48, 48),
          ),
        ),
        IconButton(
          tooltip: 'Abrir perfil',
          onPressed: onOpenProfile,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: context.lq.deepGreen,
            child: Text(
              userName.isEmpty ? 'A' : userName[0].toUpperCase(),
              style: TextStyle(
                color: context.lq.onDeepGreen,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
