import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_format.dart';

/// La acción principal de Hoy: empezar la tarea que toca ahora o, si no hay
/// ninguna, crear la siguiente.
class PriorityMissionCard extends StatelessWidget {
  const PriorityMissionCard({
    super.key,
    required this.mission,
    required this.onContinue,
    required this.onCreate,
  });

  final PriorityMission? mission;
  final VoidCallback onContinue;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final mission = this.mission;
    return LifeQuestSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LifeQuestIconTile(
                mission == null
                    ? Icons.task_alt_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission?.title ?? 'No tienes tareas pendientes',
                      style: TextStyle(
                        color: context.lq.ink,
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (mission == null)
                      Text(
                        'Escribe lo que tengas en mente y lo ordenamos.',
                        style: TextStyle(color: context.lq.muted, fontSize: 13),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _Meta(
                            Icons.schedule_rounded,
                            HomeFormat.due(mission.dueDate, DateTime.now()),
                          ),
                          _Meta(
                            Icons.flag_outlined,
                            HomeFormat.priority(mission.priority),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: mission == null ? onCreate : onContinue,
              icon: Icon(
                mission == null ? Icons.add_rounded : Icons.timer_outlined,
                size: 20,
              ),
              label: Text(mission == null ? 'Crear tarea' : 'Empezar foco'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: context.lq.muted),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            color: context.lq.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
