import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/resources_sheet.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/presentation/blocs/tasks_bloc.dart';
import 'package:proyecto_movil/features/tasks/presentation/widgets/create_task_sheet.dart';
import 'package:proyecto_movil/features/tasks/presentation/widgets/tasks_format.dart';

/// Tareas. Necesita un [TasksBloc] por encima (lo provee el router).
class TasksScreen extends StatelessWidget {
  const TasksScreen({
    super.key,
    required this.onStartFocus,
    required this.onOpenProjects,
    required this.onCreate,
  });

  /// Abre «Crear»; true si se guardó algo.
  final Future<bool> Function() onCreate;

  /// Abre Foco, con la tarea ya en la mochila si se indica.
  final void Function([String? taskId]) onStartFocus;

  /// Abre Proyectos y metas.
  final VoidCallback onOpenProjects;

  @override
  Widget build(BuildContext context) => BlocConsumer<TasksBloc, TasksState>(
    listenWhen: (_, state) =>
        state is TasksSuccess &&
        (state.message != null || state.undoTaskId != null),
    listener: (context, state) {
      state as TasksSuccess;
      if (state.undoTaskId case final id?) {
        final bloc = context.read<TasksBloc>();
        final title = state.board.tasks
            .where((t) => t.id == id)
            .firstOrNull
            ?.title;
        showLifeQuestMessage(
          context,
          title == null ? 'Tarea hecha.' : '«$title» hecha.',
          actionLabel: 'Deshacer',
          onAction: () => bloc.add(TaskDoneUndone(id)),
          duration: bloc.undoWindow,
        );
      }
      if (state.message case final message?) {
        showLifeQuestMessage(context, message);
      }
    },
    builder: (context, state) => switch (state) {
      TasksInitial() || TasksLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.green),
      ),
      TasksFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<TasksBloc>().add(const TasksRequested()),
      ),
      TasksSuccess() => RefreshIndicator(
        color: context.lq.green,
        onRefresh: () => _refresh(context.read<TasksBloc>()),
        child: _content(context, state),
      ),
    },
  );

  static Future<void> _refresh(TasksBloc bloc) {
    bloc.add(const TasksRequested());
    return bloc.stream.firstWhere(
      (state) => state is! TasksSuccess || !state.refreshing,
    );
  }

  /// Crear pasa por la hoja «Crear» (frase → propuesta), la misma de Hoy.
  Future<void> _createTask(BuildContext context, TasksSuccess state) async {
    final bloc = context.read<TasksBloc>();
    if (await onCreate()) bloc.add(const TasksRequested());
  }

  Future<void> _editTask(
    BuildContext context,
    TasksSuccess state,
    Task task,
  ) async {
    final bloc = context.read<TasksBloc>();
    final result = await showModalBottomSheet<CreateTaskResult>(
      context: context,
      // Encima de la barra y del botón «+», que tapaban los botones de abajo.
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTaskSheet(board: state.board, initial: task),
    );
    if (result == null) return;
    bloc.add(TaskEdited(task.id, result.task));
  }

  Widget _content(BuildContext context, TasksSuccess state) {
    final now = DateTime.now();
    final q = context.q;
    final tasks = state.visibleTasks;
    final idle = state.busyTaskId == null;
    // Hecha con ventana de deshacer: un toque por error no cobra nada.
    void done(String id) => context.read<TasksBloc>().add(TaskDoneStaged(id));
    Widget menu(Task task) => LifeQuestItemMenu(
      name: task.title,
      enabled: idle,
      onDone: () => done(task.id),
      onEdit: () => _editTask(context, state, task),
      onResources: () => showResourcesSheet(
        context,
        target: ResourceTarget.task(task.id),
        title: task.title,
      ),
      onRename: (title) =>
          context.read<TasksBloc>().add(TaskRenamed(task.id, title)),
      onDelete: () => context.read<TasksBloc>().add(TaskDeleted(task.id)),
      deleteMessage: 'Se borran también sus subtareas. No se puede deshacer.',
    );

    final current = tasks.isEmpty ? null : tasks.first.id;
    // Sin check a la izquierda: en Foco el check sirve para elegir tareas,
    // aquí terminarla es deslizar a la derecha o «Ya la hice».
    Widget row(Task task) => Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: idle ? DismissDirection.startToEnd : DismissDirection.none,
      dismissThresholds: const {DismissDirection.startToEnd: .45},
      confirmDismiss: (_) async {
        done(task.id);
        return true;
      },
      background: Container(
        color: q.strong,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Icon(Icons.check_rounded, color: q.onStrong),
            const SizedBox(width: 8),
            Text('Ya la hice', style: QText.label(q.onStrong)),
          ],
        ),
      ),
      child: SheetRow(
        current: task.id == current,
        time: TasksFormat.time(task.scheduledAt ?? task.dueDate),
        title: task.title,
        subtitle: [
          TasksFormat.due(task.dueDate, now),
          TasksFormat.origin(task),
          ?TasksFormat.repeat(task.repeatRule),
          ?TasksFormat.focus(task),
          '${task.xpReward} XP',
        ].join(' · '),
        trailing: menu(task),
        action: task.id == current
            ? Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SheetPill(
                    label: 'Empezar foco',
                    onTap: () => onStartFocus(task.id),
                  ),
                  TextButton.icon(
                    onPressed: idle ? () => done(task.id) : null,
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('Ya la hice'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
    final groups = _group(tasks, now);

    return LifeQuestPage(
      title: 'Tareas',
      subtitle:
          'La más urgente arriba. ¿Ya hiciste una? Deslízala a la derecha.',
      numeral: '${tasks.length}',
      numeralLabel: tasks.length == 1 ? 'abierta' : 'abiertas',
      trailing: TextButton.icon(
        onPressed: onOpenProjects,
        icon: const Icon(Icons.folder_outlined, size: 20),
        label: const Text('Proyectos'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      children: [
        if (tasks.isEmpty)
          LifeQuestEmptyState(
            illustration: LifeQuestIllustration.blank,
            title: 'No tienes tareas abiertas',
            message: 'Anota lo siguiente que quieres hacer y empieza por ahí.',
            actionLabel: 'Nueva tarea',
            onAction: idle ? () => _createTask(context, state) : null,
          )
        else ...[
          _Summary(groups: groups, tasks: tasks),
          for (final (label, group) in groups)
            if (group.isNotEmpty) ...[
              const SizedBox(height: 20),
              LifeQuestSectionHeading('$label · ${group.length}'),
              for (final task in group) row(task),
            ],
        ],
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: idle ? () => _createTask(context, state) : null,
              icon: const Icon(Icons.add),
              label: const Text('Nueva tarea'),
            ),
          ),
        ],
      ],
    );
  }

  /// Hoy (incluye lo que ya venció), próximas y sin fecha; conserva el orden
  /// de urgencia que trae el servidor dentro de cada grupo.
  static List<(String, List<Task>)> _group(List<Task> tasks, DateTime now) {
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    bool today(Task m) => m.dueDate != null && m.dueDate!.isBefore(endOfToday);
    return [
      (
        'Hoy',
        [
          for (final m in tasks)
            if (today(m)) m,
        ],
      ),
      (
        'Próximas',
        [
          for (final m in tasks)
            if (m.dueDate != null && !today(m)) m,
        ],
      ),
      (
        'Sin fecha',
        [
          for (final m in tasks)
            if (m.dueDate == null) m,
        ],
      ),
    ];
  }
}

/// Bloque de resumen: cuántas tocan hoy, cuántas después y la XP en juego.
class _Summary extends StatelessWidget {
  const _Summary({required this.groups, required this.tasks});

  final List<(String, List<Task>)> groups;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    color: context.q.tint,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: LifeQuestStat(
            value: '${groups[0].$2.length}',
            label: 'Para hoy',
          ),
        ),
        Expanded(
          child: LifeQuestStat(
            value: '${groups[1].$2.length + groups[2].$2.length}',
            label: 'Después',
          ),
        ),
        Expanded(
          child: LifeQuestStat(
            value: '${tasks.fold(0, (sum, m) => sum + m.xpReward)}',
            label: 'XP en juego',
          ),
        ),
      ],
    ),
  );
}
