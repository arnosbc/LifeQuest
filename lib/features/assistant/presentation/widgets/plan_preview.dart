import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/assistant_bloc.dart';

/// Contenido de la hoja «Armar mi día» / «Replanificar»: la propuesta y un
/// botón para aceptarla. Al aceptar cierra la hoja con `true`.
class PlanPreview extends StatelessWidget {
  const PlanPreview({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<AssistantBloc, AssistantState>(
        listenWhen: (_, s) =>
            s is AssistantApplied ||
            (s is AssistantProposal && s.message != null),
        listener: (context, state) => switch (state) {
          AssistantApplied() => Navigator.pop(context, true),
          AssistantProposal(:final message?) => showLifeQuestMessage(
            context,
            message,
          ),
          _ => null,
        },
        builder: (context, state) => switch (state) {
          AssistantInitial() ||
          AssistantLoading() ||
          AssistantApplied() => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          AssistantFailure(:final message) => Text(
            message,
            style: QText.body(context.q.text2),
          ),
          AssistantProposal() => _proposal(context, state),
        },
      );

  Widget _proposal(BuildContext context, AssistantProposal state) {
    final q = context.q;
    final plan = state.plan;
    if (plan.blocks.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            plan.left.isEmpty
                ? (plan.mode == PlanMode.planDay
                      ? 'Todo lo pendiente ya tiene hora. Buen trabajo.'
                      : 'Nada atrasado. Vas al día.')
                : 'Hoy ya no quedan huecos libres. Mañana hay más espacio.',
            style: QText.body(q.text2),
          ),
          const SizedBox(height: 16),
          QuestlyButton(
            label: 'Entendido',
            variant: QuestlyButtonVariant.secondary,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          plan.mode == PlanMode.planDay
              ? 'Así quedaría tu día. Puedes mover cualquier bloque después.'
              : 'Esto se movería al siguiente hueco libre.',
          style: QText.body(q.text2),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final block in plan.blocks)
                SheetRow(
                  leading: const SheetCheck(done: false),
                  time: _time(block.start),
                  title: block.title,
                  subtitle: [
                    if (!_sameDay(block.start, DateTime.now())) 'Mañana',
                    'Hasta las ${_time(block.end)}',
                  ].join(' · '),
                ),
              if (plan.left.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    plan.left.length == 1
                        ? '1 tarea no cabe hoy; queda sin hora.'
                        : '${plan.left.length} tareas no caben hoy; quedan sin hora.',
                    style: QText.body(q.text2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        QuestlyButton(
          label: state.saving
              ? 'Guardando…'
              : 'Aceptar ${plan.blocks.length} '
                    '${plan.blocks.length == 1 ? 'bloque' : 'bloques'}',
          onPressed: state.saving
              ? null
              : () => context.read<AssistantBloc>().add(
                  const AssistantPlanAccepted(),
                ),
        ),
        const SizedBox(height: 8),
        QuestlyButton(
          label: 'Ahora no',
          variant: QuestlyButtonVariant.text,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
