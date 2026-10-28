import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/bad_habits_view.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/create_habit_sheet.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/good_habits_view.dart';
import 'package:proyecto_movil/features/habits/presentation/widgets/habit_tab_button.dart';

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
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      HabitsFailure(:final message) => _ErrorView(
        message: message,
        onRetry: () => context.read<HabitsBloc>().add(const HabitsRequested()),
      ),
      HabitsSuccess() => RefreshIndicator(
        color: context.lq.deepGreen,
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
    return LifeQuestPage(
      title: 'Hábitos',
      subtitle: 'La constancia también es una aventura.',
      children: [
        Row(
          children: [
            Expanded(
              child: HabitTabButton(
                label: 'Buenos hábitos',
                selected: !_showBadHabits,
                onTap: () => setState(() => _showBadHabits = false),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: HabitTabButton(
                label: 'Malos hábitos',
                selected: _showBadHabits,
                onTap: () => setState(() => _showBadHabits = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        if (_showBadHabits)
          BadHabitsView(
            board: state.board,
            busyHabitId: state.busyHabitId,
            onRegister: idle ? (id) => bloc.add(BadHabitRegistered(id)) : null,
            menuFor: menu,
          )
        else
          GoodHabitsView(
            board: state.board,
            now: DateTime.now(),
            busyHabitId: state.busyHabitId,
            onComplete: idle ? (id) => bloc.add(GoodHabitCompleted(id)) : null,
            menuFor: menu,
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: idle ? () => _create(context, state) : null,
            icon: state.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(state.saving ? 'Creando hábito…' : 'Nuevo hábito'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.lq.ink),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}
