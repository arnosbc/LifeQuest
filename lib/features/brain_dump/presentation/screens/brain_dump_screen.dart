import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/presentation/blocs/brain_dump_bloc.dart';
import 'package:proyecto_movil/features/brain_dump/presentation/widgets/gtd_sheet.dart';

/// Brain Dump: capturar sin fricción y diagnosticar con G.T.D. Necesita un
/// [BrainDumpBloc] por encima.
class BrainDumpScreen extends StatefulWidget {
  const BrainDumpScreen({super.key, required this.onCreateGoal});

  /// Una Meta pasa por S.M.A.R.T. en Stage (RF-014).
  final VoidCallback onCreateGoal;

  @override
  State<BrainDumpScreen> createState() => _BrainDumpScreenState();
}

class _BrainDumpScreenState extends State<BrainDumpScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _capture(BrainDumpBloc bloc) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    bloc.add(ThoughtCaptured(text));
    _input.clear();
  }

  Future<void> _diagnose(BrainDumpBloc bloc, Thought thought) async {
    final outcome = await showModalBottomSheet<GtdOutcome>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GtdSheet(thought: thought),
    );
    if (outcome == null) return;
    if (outcome.goal) {
      // La idea sigue en la bandeja hasta que la Meta exista en Stage.
      widget.onCreateGoal();
    } else if (outcome.shelf case final shelf?) {
      bloc.add(ThoughtFiled(thought.id, shelf));
    } else if (outcome.conversion case final conversion?) {
      bloc.add(ThoughtConverted(conversion));
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<BrainDumpBloc, BrainDumpState>(
        listenWhen: (_, s) => s is BrainDumpSuccess && s.message != null,
        listener: (context, s) =>
            showLifeQuestMessage(context, (s as BrainDumpSuccess).message!),
        builder: (context, state) => switch (state) {
          BrainDumpInitial() || BrainDumpLoading() => Center(
            child: CircularProgressIndicator(color: context.lq.deepGreen),
          ),
          BrainDumpFailure(:final message) => LifeQuestErrorView(
            message: message,
            onRetry: () =>
                context.read<BrainDumpBloc>().add(const BrainDumpRequested()),
          ),
          BrainDumpSuccess() => RefreshIndicator(
            color: context.lq.deepGreen,
            onRefresh: () async {
              final bloc = context.read<BrainDumpBloc>()
                ..add(const BrainDumpRequested());
              await bloc.stream.firstWhere(
                (s) => s is! BrainDumpSuccess || !s.refreshing,
              );
            },
            child: _content(context, state),
          ),
        },
      );

  Widget _content(BuildContext context, BrainDumpSuccess state) {
    final bloc = context.read<BrainDumpBloc>();
    final board = state.board;
    final idle = state.busyKey == null;
    return LifeQuestPage(
      title: 'Brain Dump',
      subtitle: 'Saca de tu cabeza todo lo pendiente. Luego decides.',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _capture(bloc),
                decoration: const InputDecoration(
                  hintText: '¿Qué tienes en mente?',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: idle ? () => _capture(bloc) : null,
              tooltip: 'Capturar',
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: state.busyKey == 'capture'
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
            ),
          ],
        ),
        LifeQuestSectionHeading('BANDEJA · ${board.inbox.length}'),
        const SizedBox(height: 7),
        if (board.inbox.isEmpty)
          LifeQuestListRow(
            icon: Icons.inbox_outlined,
            title: 'Bandeja vacía',
            subtitle: board.convertedToday > 0
                ? 'Hoy convertiste ${board.convertedToday} ideas en acción.'
                : 'Escribe arriba lo que tengas en mente.',
          ),
        for (final t in board.inbox)
          LifeQuestActionRow(
            icon: Icons.lightbulb_outline,
            title: t.content,
            subtitle: 'Capturada el ${LifeQuestDates.dayTime(t.createdAt)}',
            actionLabel: 'Decidir',
            busy: state.busyKey == t.id,
            onAction: idle ? () => _diagnose(bloc, t) : null,
          ),
        _shelf(context, state, 'ALGÚN DÍA', board.someday),
        _shelf(context, state, 'REFERENCIA', board.reference),
      ],
    );
  }

  Widget _shelf(
    BuildContext context,
    BrainDumpSuccess state,
    String label,
    List<Thought> thoughts,
  ) {
    if (thoughts.isEmpty) return const SizedBox.shrink();
    final bloc = context.read<BrainDumpBloc>();
    final idle = state.busyKey == null;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: LifeQuestSectionHeading('$label · ${thoughts.length}'),
        children: [
          for (final t in thoughts)
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.content,
                    style: TextStyle(color: context.lq.ink, fontSize: 13),
                  ),
                ),
                IconButton(
                  tooltip: 'Devolver a la bandeja',
                  onPressed: idle
                      ? () => bloc.add(ThoughtFiled(t.id, ThoughtShelf.pending))
                      : null,
                  icon: const Icon(Icons.move_to_inbox_outlined),
                ),
                IconButton(
                  tooltip: 'Borrar',
                  onPressed: idle
                      ? () async {
                          if (await confirmLifeQuest(
                            context,
                            title: 'Borrar idea',
                            message: '“${t.content}” se borrará.',
                            confirmLabel: 'Borrar',
                          )) {
                            bloc.add(ThoughtDeleted(t.id));
                          }
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
