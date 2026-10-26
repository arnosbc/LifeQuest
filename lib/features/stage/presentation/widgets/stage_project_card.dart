import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// Proyecto desplegable: progreso y urgencia arriba; al abrirlo, sus
/// misiones (con ✓ para completarlas) y las acciones del proyecto.
class StageProjectCard extends StatelessWidget {
  const StageProjectCard({
    super.key,
    required this.project,
    required this.urgencyLabel,
    required this.onCompleteTask,
    required this.onComplete,
    required this.onArchive,
    required this.onAddMission,
  });

  final StageProject project;

  /// "🔴 Alta", "🟡 Media" o "🟢 Baja": símbolo + texto.
  final String urgencyLabel;

  /// Null mientras otra acción está en curso.
  final ValueChanged<String>? onCompleteTask;
  final VoidCallback? onComplete;
  final VoidCallback? onArchive;
  final VoidCallback onAddMission;

  @override
  Widget build(BuildContext context) {
    final details = [
      project.skillName ?? 'Sin área asignada',
      if (project.goalTitle case final goal?) 'Meta: $goal',
      if (project.endDate case final end?) 'hasta ${end.day}/${end.month}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: LifeQuestSurface(
        padding: EdgeInsets.zero,
        // Material propio: el toque del ExpansionTile se ve sobre el fondo.
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            // Sin las líneas que ExpansionTile pinta al abrirse.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              leading: const LifeQuestIconTile(Icons.work_outline),
              title: Text(
                project.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$details\n${project.tasksDone} de ${project.tasksTotal} misiones · $urgencyLabel',
                    style: const TextStyle(
                      color: LifeQuestColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: project.tasksTotal == 0
                        ? 0
                        : project.tasksDone / project.tasksTotal,
                    minHeight: 4,
                    color: LifeQuestColors.deepGreen,
                    backgroundColor: LifeQuestColors.line,
                  ),
                ],
              ),
              children: [
                if (project.tasks.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Aún no tiene misiones.',
                      style: TextStyle(
                        color: LifeQuestColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                for (final task in project.tasks)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: task.done
                                ? LifeQuestColors.muted
                                : LifeQuestColors.ink,
                            fontSize: 11,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (task.done)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.check_circle,
                            color: LifeQuestColors.green,
                            size: 22,
                            semanticLabel: 'Completada',
                          ),
                        )
                      else
                        IconButton(
                          tooltip: 'Completar «${task.title}»',
                          onPressed: onCompleteTask == null
                              ? null
                              : () => onCompleteTask!(task.id),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: LifeQuestColors.deepGreen,
                          ),
                        ),
                    ],
                  ),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton.icon(
                      onPressed: onAddMission,
                      icon: const Icon(Icons.add),
                      label: const Text('Misión'),
                    ),
                    if (project.canComplete)
                      FilledButton.tonal(
                        onPressed: onComplete,
                        child: const Text('Completar proyecto'),
                      ),
                    TextButton(
                      onPressed: onArchive,
                      child: const Text('Archivar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
