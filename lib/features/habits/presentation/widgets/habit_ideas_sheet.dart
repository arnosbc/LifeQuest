import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit_idea.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/features/habits/domain/usecases/habit_plan_usecases.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_time.dart';

/// «Ideas de Nevi»: 3 hábitos sugeridos; devuelve el que la persona elige
/// (con su hora) o null. Nevi solo propone: nada se crea sin tocar «Crear».
Future<NewHabit?> showHabitIdeasSheet(
  BuildContext context,
  SuggestHabits suggest,
) => showModalBottomSheet<NewHabit>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: context.q.card,
  builder: (_) => _HabitIdeasSheet(suggest),
);

class _HabitIdeasSheet extends StatefulWidget {
  const _HabitIdeasSheet(this.suggest);

  final SuggestHabits suggest;

  @override
  State<_HabitIdeasSheet> createState() => _HabitIdeasSheetState();
}

class _HabitIdeasSheetState extends State<_HabitIdeasSheet> {
  List<HabitIdea> _ideas = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.suggest(const NoParams());
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.match((f) => _error = f.message, (ideas) => _ideas = ideas);
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MascotPose(pose: _loading ? 'pensando' : 'planta', size: 72),
              const SizedBox(width: QSpace.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ideas de Nevi', style: QText.title3(q.text)),
                    Text(
                      'Hábitos pequeños pensados para ti. Elige uno y empieza hoy.',
                      style: QText.body(q.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: QSpace.m),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(QSpace.l),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            for (final idea in _ideas) _IdeaCard(idea),
            if (_error case final error?)
              Text(error, style: QText.body(q.coral)),
          ],
          const SizedBox(height: QSpace.m),
          QuestlyButton(
            label: 'Otras ideas',
            icon: QIcons.spark,
            variant: QuestlyButtonVariant.tonal,
            onPressed: _loading ? null : _load,
            disabledReason: 'Nevi está pensando…',
          ),
        ],
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard(this.idea);

  final HabitIdea idea;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.only(bottom: QSpace.s),
      child: QuestlyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(idea.name, style: QText.title3(q.text)),
            if (idea.why.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(idea.why, style: QText.body(q.text2)),
            ],
            if (idea.time case final time?) ...[
              const SizedBox(height: 4),
              Text(
                '⏰ ${habitTimeLabel(time)} · Nevi te avisa',
                style: QText.meta(q.text3),
              ),
            ],
            const SizedBox(height: QSpace.s),
            QuestlyButton(
              label: 'Crear este hábito',
              icon: QIcons.plus,
              onPressed: () => Navigator.of(context).pop(
                NewHabit(
                  name: idea.name,
                  type: HabitType.good,
                  reminderTime: idea.time,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
