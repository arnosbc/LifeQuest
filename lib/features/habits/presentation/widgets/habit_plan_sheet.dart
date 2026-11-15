import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit_plan.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/habit_plan_usecases.dart';

/// «Plan de Nevi» de un hábito (065): lo muestra o lo pide a la IA.
Future<void> showHabitPlanSheet(
  BuildContext context, {
  required Habit habit,
  required GetHabitPlan getPlan,
  required GenerateHabitPlan generatePlan,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: context.q.card,
  builder: (_) => _HabitPlanSheet(
    habit: habit,
    getPlan: getPlan,
    generatePlan: generatePlan,
  ),
);

class _HabitPlanSheet extends StatefulWidget {
  const _HabitPlanSheet({
    required this.habit,
    required this.getPlan,
    required this.generatePlan,
  });

  final Habit habit;
  final GetHabitPlan getPlan;
  final GenerateHabitPlan generatePlan;

  @override
  State<_HabitPlanSheet> createState() => _HabitPlanSheetState();
}

class _HabitPlanSheetState extends State<_HabitPlanSheet> {
  HabitPlan? _plan;
  String? _error;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    widget.getPlan(widget.habit.id).then((result) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        result.match((f) => _error = f.message, (plan) => _plan = plan);
      });
    });
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    final result = await widget.generatePlan(widget.habit.id);
    if (!mounted) return;
    setState(() {
      _generating = false;
      result.match((f) => _error = f.message, (plan) => _plan = plan);
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final plan = _plan;
    final bad = widget.habit.type == HabitType.bad;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MascotPose(
                pose: plan == null ? 'pensando' : 'saludando',
                size: 72,
              ),
              const SizedBox(width: QSpace.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan de Nevi', style: QText.title3(q.text)),
                    Text(widget.habit.name, style: QText.body(q.text2)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: QSpace.m),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (plan == null)
            Text(
              bad
                  ? 'Te ayudo a dejarlo: cómo esquivar lo que lo dispara y con qué reemplazarlo en 2 minutos.'
                  : 'Te ayudo a que se vuelva automático: una versión de 2 minutos, cuándo hacerla y cómo celebrarla.',
              style: QText.body(q.text),
            )
          else ...[
            _Field(
              bad ? 'Reemplazo de 2 minutos' : 'Versión mínima',
              plan.tiny,
            ),
            if (plan.cue case final cue?)
              _Field(bad ? 'Cómo evitar el disparador' : 'Cuándo hacerlo', cue),
            if (plan.reward case final reward?) _Field('Tu recompensa', reward),
            if (plan.why case final why?) _Field('Por qué importa', why),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: QSpace.s),
            Text(error, style: QText.body(q.coral)),
          ],
          const SizedBox(height: QSpace.l),
          QuestlyButton(
            label: plan == null ? 'Que Nevi arme mi plan' : 'Rehacer el plan',
            icon: QIcons.spark,
            onPressed: _loading || _generating ? null : _generate,
            disabledReason: _generating
                ? 'Nevi está pensando tu plan…'
                : 'Cargando…',
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.text);

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.only(bottom: QSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: QText.label(q.accent).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(text, style: QText.body(q.text)),
        ],
      ),
    );
  }
}
