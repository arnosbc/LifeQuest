import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

class DashboardGreeting extends StatelessWidget {
  const DashboardGreeting({
    super.key,
    required this.userName,
    required this.subtitle,
    required this.onOpenProfile,
    this.now,
  });

  final String userName;
  final String subtitle;
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
                  color: context.lq.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$greeting, $userName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.lq.ink,
                  fontSize: 26,
                  height: 1.2,
                  letterSpacing: -0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: context.lq.muted, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
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
