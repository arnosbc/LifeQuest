import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/bad_habits_view.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/create_habit_sheet.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/good_habits_view.dart';

/// Hábitos. Necesita un [HabitsBloc] por encima (lo provee el router).
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  bool _showBadHabits = false;

  @override
  Widget build(BuildContext context) => BlocConsumer<HabitsBloc, HabitsState>(
    listenWhen: (_, state) => state is HabitsSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as HabitsSuccess).message!),
    builder: (context, state) => switch (state) {
      HabitsInitial() || HabitsLoading() => Center(
        child: CircularProgressIndicator(color: context.q.ink),
      ),
      HabitsFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<HabitsBloc>().add(const HabitsRequested()),
      ),
      HabitsSuccess() => RefreshIndicator(
        color: context.q.ink,
        onRefresh: () => _refresh(context.read<HabitsBloc>()),
        child: _content(context, state),
      ),
    },
  );
  static Future<void> _refresh(HabitsBloc bloc) {
    bloc.add(const HabitsRequested());
    return bloc.stream.firstWhere(
      (state) => state is! HabitsSuccess || !state.refreshing,
    );
  }

  Future<void> _create(BuildContext context, HabitsSuccess state) async {
    final bloc = context.read<HabitsBloc>();
    final habit = await showModalBottomSheet<NewHabit>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateHabitSheet(
        type: _showBadHabits ? HabitType.bad : HabitType.good,
        skills: state.board.skills,
      ),
    );
    if (habit != null) bloc.add(HabitCreated(habit));
  }

  Widget _content(BuildContext context, HabitsSuccess state) {
    final bloc = context.read<HabitsBloc>();
    final idle = state.busyHabitId == null && !state.saving;
    Widget menu(Habit habit) => LifeQuestItemMenu(
      name: habit.name,
      enabled: idle,
      maxLength: 100,
      onRename: (name) => bloc.add(HabitRenamed(habit.id, name)),
      onDelete: () => bloc.add(HabitDeleted(habit.id)),
      deleteMessage: 'Se borra también su historial y su racha.',
    );
    final today = [
      for (final h in state.board.good)
        if (h.scheduledToday) h,
    ];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        QuestlyHero(
          kicker: 'Tus rutinas',
          heading: 'Hábitos',
          icon: QIcons.leaf,
          onAction: idle ? () => _create(context, state) : null,
          actionLabel: 'Crear hábito',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TodayRing(
                done: today.where((h) => h.doneToday).length,
                total: today.length,
              ),
              const SizedBox(height: QSpace.l),
              QuestlySegmented<bool>(
                segments: const [(false, 'Buenos'), (true, 'Malos')],
                selected: _showBadHabits,
                onChanged: (bad) => setState(() => _showBadHabits = bad),
              ),
              const SizedBox(height: QSpace.m),
              if (_showBadHabits)
                BadHabitsView(
                  board: state.board,
                  busyHabitId: state.busyHabitId,
                  onRegister: idle
                      ? (id) => bloc.add(BadHabitRegistered(id))
                      : null,
                  menuFor: menu,
                )
              else
                GoodHabitsView(
                  board: state.board,
                  now: DateTime.now(),
                  busyHabitId: state.busyHabitId,
                  onComplete: idle
                      ? (id) => bloc.add(GoodHabitCompleted(id))
                      : null,
                  menuFor: menu,
                ),
              const SizedBox(height: QSpace.l),
              QuestlyButton(
                label: state.saving ? 'Creando hábito…' : 'Nuevo hábito',
                icon: QIcons.plus,
                variant: QuestlyButtonVariant.tonal,
                onPressed: idle ? () => _create(context, state) : null,
                disabledReason: state.saving ? 'Creando hábito…' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// «Hoy» (Habitos.dc.html, Ritual de hoy): anillo con los hábitos buenos
/// cumplidos de los que tocan hoy.
class _TodayRing extends StatelessWidget {
  const _TodayRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final text = total == 0
        ? 'Hoy no tienes hábitos buenos programados.'
        : done == total
        ? '¡Cumpliste los $total de hoy!'
        : '$done de $total hábitos buenos cumplidos';
    return QuestlyCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hoy', style: QText.title3(q.text).copyWith(fontSize: 17)),
                const SizedBox(height: QSpace.xs),
                Text(text, style: QText.body(q.text2).copyWith(fontSize: 14)),
              ],
            ),
          ),
          Semantics(
            label: 'Progreso de hoy: $done de $total',
            excludeSemantics: true,
            child: SizedBox.square(
              dimension: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: total == 0 ? 0 : done / total),
                    duration: context.motion(const Duration(milliseconds: 600)),
                    builder: (_, v, _) => SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        color: q.accent,
                        backgroundColor: q.border,
                      ),
                    ),
                  ),
                  Text('$done/$total', style: QText.number(q.text, size: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
