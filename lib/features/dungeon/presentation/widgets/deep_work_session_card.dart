import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/dungeon/domain/entities/dungeon_board.dart';
import 'package:proyecto_movil/features/dungeon/presentation/widgets/cycle_duration_card.dart';

/// La sesión en curso: avance, lo que se hace AHORA (el paso que toca o el
/// hábito, 068) y lo demás de la sesión para cambiar de foco.
class DeepWorkSessionCard extends StatelessWidget {
  const DeepWorkSessionCard({
    super.key,
    required this.session,
    required this.currentTaskId,
    required this.busy,
    required this.onSelect,
    required this.onComplete,
    required this.onStepDone,
    required this.onHabitDone,
    required this.onOpenSteps,
  });

  final DungeonSession session;
  final String? currentTaskId;

  /// Mientras otra acción está en curso los botones se apagan.
  final bool busy;
  final ValueChanged<String> onSelect;

  /// Completar una tarea sin pasos pendientes.
  final ValueChanged<String> onComplete;
  final ValueChanged<String> onStepDone;
  final ValueChanged<String> onHabitDone;

  /// Abre la tarea guiada: revisar con fotos o dividir en pasos.
  final ValueChanged<String> onOpenSteps;

  @override
  Widget build(BuildContext context) {
    final items = session.items;
    final done = items.where((t) => t.done).length;
    final current = items.where((t) => t.id == currentTaskId).firstOrNull;
    final others = items.where((t) => t.id != current?.id).toList();
    return LifeQuestSurface(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LifeQuestStat(
                  value: CycleDurationCard.hours(session.totalMinutes),
                  label: 'Duración total',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: LifeQuestStat(
                  value: '$done / ${items.length}',
                  label: 'Cumplidas',
                ),
              ),
            ],
          ),
          if (current != null) ...[
            const SizedBox(height: 11),
            _label(context, 'AHORA'),
            const SizedBox(height: 5),
            _now(context, current),
          ],
          if (others.isNotEmpty) ...[
            const SizedBox(height: 11),
            _label(context, 'TAMBIÉN EN ESTA SESIÓN'),
            Text(
              'Toca una para concentrarte en ella.',
              style: TextStyle(color: context.lq.muted, fontSize: 9),
            ),
            for (final item in others) _other(context, item),
          ],
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      color: context.lq.muted,
      fontSize: 9,
      fontWeight: FontWeight.w800,
    ),
  );

  /// Lo que toca: el paso actual con sus botones, el hábito o la tarea sola.
  Widget _now(BuildContext context, DungeonTask item) {
    final step = item.step;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.lq.softGreen,
        border: Border.all(color: context.lq.deepGreen),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.title,
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.done
                ? (item.isHabit ? 'Hábito cumplido hoy' : 'Tarea completada')
                : item.isHabit
                ? 'Hábito de hoy'
                : step != null
                ? 'Paso ${step.position} de ${item.stepCount}'
                      '${step.minutes == null ? '' : ' · ~${step.minutes} min'}'
                : 'Sin pasos pendientes',
            style: TextStyle(
              color: context.lq.deepGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (step != null && !item.done) ...[
            const SizedBox(height: 7),
            Text(step.title, style: TextStyle(color: context.lq.ink, fontSize: 13)),
          ],
          if (!item.done) ...[
            const SizedBox(height: 10),
            if (item.isHabit)
              _primary(
                context,
                Icons.check_circle_outline,
                'Marcar hábito como hecho',
                () => onHabitDone(item.id),
              )
            else if (step != null) ...[
              _primary(
                context,
                Icons.check_rounded,
                'Listo, siguiente paso',
                () => onStepDone(step.id),
              ),
              const SizedBox(height: 6),
              _secondary(
                Icons.photo_camera_outlined,
                'Revisar con fotos',
                () => onOpenSteps(item.id),
              ),
            ] else ...[
              _primary(
                context,
                Icons.check_circle_outline,
                'Completar tarea',
                () => onComplete(item.id),
              ),
              const SizedBox(height: 6),
              _secondary(
                Icons.format_list_numbered_rounded,
                'Ver o dividir en pasos',
                () => onOpenSteps(item.id),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _primary(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => SizedBox(
    height: 48,
    child: FilledButton.icon(
      onPressed: busy ? null : onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(backgroundColor: context.lq.deepGreen),
    ),
  );

  Widget _secondary(IconData icon, String label, VoidCallback onTap) =>
      SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: busy ? null : onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      );

  Widget _other(BuildContext context, DungeonTask item) {
    final step = item.step;
    final detail = item.done
        ? (item.isHabit ? 'Cumplido hoy' : 'Completada')
        : item.isHabit
        ? 'Hábito de hoy'
        : step != null
        ? 'Paso ${step.position} de ${item.stepCount}'
        : 'Tarea';
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: context.lq.background,
        border: Border.all(color: context.lq.line),
        borderRadius: BorderRadius.circular(9),
      ),
      // Material propio: el toque del ListTile se ve sobre el fondo.
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          dense: true,
          onTap: item.done ? null : () => onSelect(item.id),
          leading: Icon(
            item.done
                ? Icons.check_circle
                : item.isHabit
                ? Icons.repeat_rounded
                : Icons.radio_button_unchecked,
            color: item.done ? context.lq.green : context.lq.muted,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              decoration: item.done ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            detail,
            style: TextStyle(color: context.lq.muted, fontSize: 10),
          ),
        ),
      ),
    );
  }
}
