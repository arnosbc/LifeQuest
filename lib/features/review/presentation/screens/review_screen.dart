import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/review/presentation/blocs/review_bloc.dart';

/// Cierre del día (y de la semana): lo que hiciste y, para cada pendiente, una decisión
/// (pasar a la otra semana o soltarla). Necesita un [ReviewBloc] encima.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, this.onOpenInbox});

  /// Abre la Bandeja; al volver se relee la revisión.
  final Future<void> Function()? onOpenInbox;

  @override
  Widget build(BuildContext context) => BlocConsumer<ReviewBloc, ReviewState>(
    listenWhen: (_, s) => s is ReviewSuccess && s.message != null,
    listener: (context, s) =>
        showLifeQuestMessage(context, (s as ReviewSuccess).message!),
    builder: (context, state) => switch (state) {
      ReviewInitial() || ReviewLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.green),
      ),
      ReviewFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<ReviewBloc>().add(const ReviewRequested()),
      ),
      ReviewSuccess() => _content(context, state),
    },
  );

  Widget _content(BuildContext context, ReviewSuccess state) {
    final r = state.review;
    final bloc = context.read<ReviewBloc>();
    final idle = state.busyTaskId == null;
    final now = DateTime.now();
    return LifeQuestPage(
      title: 'Cierra el día',
      subtitle: 'Decide qué sigue: mañana, la otra semana o soltarlo.',
      numeral: '${r.pending.length}',
      numeralLabel: 'por decidir',
      children: [
        const LifeQuestSectionHeading('ESTA SEMANA'),
        Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '${r.done}', label: 'Tareas hechas'),
            ),
            Expanded(
              child: LifeQuestStat(
                value: '${r.focusMinutes} min',
                label: 'Foco',
              ),
            ),
            Expanded(
              child: LifeQuestStat(
                value: '${r.habitDays}',
                label: 'Hábitos cumplidos',
              ),
            ),
          ],
        ),
        if (r.inbox > 0 && onOpenInbox != null) ...[
          const SizedBox(height: 20),
          SheetRow(
            title: r.inbox == 1
                ? '1 nota sin decidir en la Bandeja'
                : '${r.inbox} notas sin decidir en la Bandeja',
            subtitle: 'Conviértelas en tarea o suéltalas.',
            action: SheetPill(
              label: 'Decidir',
              onTap: () async {
                await onOpenInbox!();
                bloc.add(const ReviewRequested());
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        LifeQuestSectionHeading('PENDIENTE · ${r.pending.length}'),
        if (r.pending.isEmpty)
          const LifeQuestEmptyState(
            compact: true,
            illustration: LifeQuestIllustration.done,
            title: 'Semana cerrada',
            message: 'No queda nada vencido. Empieza la próxima con calma.',
          ),
        for (final task in r.pending)
          SheetRow(
            leading: SheetCheck(done: false, busy: state.busyTaskId == task.id),
            title: task.title,
            subtitle: _due(task.due, now),
            trailing: IconButton(
              tooltip: 'Soltar «${task.title}»',
              onPressed: !idle
                  ? null
                  : () async {
                      if (await confirmLifeQuest(
                        context,
                        title: '¿Soltar «${task.title}»?',
                        message:
                            'Se borra la tarea. Decidir no hacerla también es '
                            'avanzar.',
                        confirmLabel: 'Soltar',
                      )) {
                        bloc.add(ReviewTaskDropped(task.id));
                      }
                    },
              icon: const Icon(Icons.close_rounded),
            ),
            action: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SheetPill(
                  label: 'Mañana',
                  onTap: idle
                      ? () => bloc.add(ReviewTaskPostponed(task.id, days: 1))
                      : null,
                ),
                TextButton(
                  onPressed: idle
                      ? () => bloc.add(ReviewTaskPostponed(task.id))
                      : null,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: const Text('A la otra semana'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

  static String _due(DateTime? due, DateTime now) {
    if (due == null) return 'Sin fecha';
    final day = '${_weekdays[due.weekday - 1]} ${due.day}/${due.month}';
    return due.isBefore(now) ? 'Pendiente desde el $day' : 'Para el $day';
  }
}
