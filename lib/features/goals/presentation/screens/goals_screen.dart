import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/goals/domain/entities/goals_board.dart';
import 'package:proyecto_movil/features/goals/presentation/blocs/goals_bloc.dart';

/// Objetivos: cada Meta es un jefe. Atacar = completar una tarea o un
/// proyecto vinculado. Necesita un [GoalsBloc] por encima.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.onCreateGoal});

  /// Las Metas se crean con S.M.A.R.T. desde Stage.
  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) => BlocConsumer<GoalsBloc, GoalsState>(
    listenWhen: (_, s) => s is GoalsSuccess && s.message != null,
    listener: (context, s) =>
        showLifeQuestMessage(context, (s as GoalsSuccess).message!),
    builder: (context, state) => switch (state) {
      GoalsInitial() || GoalsLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      GoalsFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<GoalsBloc>().add(const GoalsRequested()),
      ),
      GoalsSuccess() => RefreshIndicator(
        color: context.lq.deepGreen,
        onRefresh: () async {
          final bloc = context.read<GoalsBloc>()..add(const GoalsRequested());
          await bloc.stream.firstWhere(
            (s) => s is! GoalsSuccess || !s.refreshing,
          );
        },
        child: LifeQuestPage(
          title: 'Objetivos',
          subtitle: 'Cada meta es un jefe que puedes vencer.',
          children: [
            if (state.board.goals.isEmpty)
              const LifeQuestListRow(
                icon: Icons.flag_outlined,
                title: 'Aún no hay jefes a la vista',
                subtitle:
                    'Crea una meta S.M.A.R.T. y cada misión vinculada la golpeará.',
              ),
            for (final goal in state.board.goals)
              _BossCard(goal: goal, state: state),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onCreateGoal,
                icon: const Icon(Icons.add),
                label: const Text('Nueva meta en Stage'),
              ),
            ),
          ],
        ),
      ),
    },
  );
}

class _BossCard extends StatelessWidget {
  const _BossCard({required this.goal, required this.state});

  final BossGoal goal;
  final GoalsSuccess state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GoalsBloc>();
    final idle = state.busyKey == null;
    final ratio = goal.maxHp == 0 ? 0.0 : goal.currentHp / goal.maxHp;
    final (skin, skinColor) = switch (goal.status) {
      GoalStatus.completed => ('Éxito', context.lq.deepGreen),
      GoalStatus.expired => ('El jefe escapó… por ahora', context.lq.muted),
      _ => ('¡Sigue así!', context.lq.deepGreen),
    };
    final smart = [
      ('Específica', goal.smart.specific),
      ('Medible', goal.smart.measurable),
      ('Alcanzable', goal.smart.achievable),
      ('Relevante', goal.smart.relevant),
      ('Temporal', goal.smart.timebound),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LifeQuestSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const LifeQuestIconTile(Icons.whatshot),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                      color: context.lq.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    skin,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: skinColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              label: 'Vida del jefe: ${goal.currentHp} de ${goal.maxHp}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  color: context.lq.error,
                  backgroundColor: context.lq.line,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                'Vida ${goal.currentHp}/${goal.maxHp}',
                if (goal.dueDate != null)
                  'Hasta el ${LifeQuestDates.day(goal.dueDate!)}',
                ?goal.skillName,
              ].join(' · '),
              style: TextStyle(color: context.lq.muted, fontSize: 11),
            ),
            if (goal.active) ...[
              const SizedBox(height: 12),
              const LifeQuestSectionHeading('ATAQUES DISPONIBLES'),
              const SizedBox(height: 7),
              if (goal.attacks.isEmpty)
                Text(
                  'Vincula misiones o proyectos a esta meta desde Stage para atacar.',
                  style: TextStyle(color: context.lq.muted, fontSize: 12),
                ),
              for (final a in goal.attacks)
                LifeQuestActionRow(
                  icon: a.kind == AttackKind.project
                      ? Icons.folder_outlined
                      : Icons.bolt,
                  title: a.title,
                  subtitle: a.kind == AttackKind.project
                      ? 'Proyecto · −${a.damage} de vida'
                      : 'Misión · −${a.damage} de vida',
                  actionLabel: 'Atacar',
                  busy: state.busyKey == a.id,
                  onAction: idle
                      ? () => bloc.add(BossAttacked(goalId: goal.id, attack: a))
                      : null,
                ),
            ] else ...[
              const SizedBox(height: 10),
              if (goal.status == GoalStatus.expired)
                Text(
                  'Conservas toda la XP ganada. Puedes replantear la meta '
                  'en Stage o archivarla.',
                  style: TextStyle(color: context.lq.ink, fontSize: 12),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: idle
                      ? () => bloc.add(GoalArchived(goal.id))
                      : null,
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archivar'),
                ),
              ),
            ],
            if (goal.hits.isNotEmpty) ...[
              const SizedBox(height: 8),
              const LifeQuestSectionHeading('GOLPES RECIENTES'),
              const SizedBox(height: 4),
              for (final h in goal.hits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '−${h.damage} · ${h.title}'
                    '${h.at == null ? '' : ' · ${LifeQuestDates.day(h.at!)}'}',
                    style: TextStyle(color: context.lq.ink, fontSize: 12),
                  ),
                ),
            ],
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Ficha S.M.A.R.T.',
                  style: TextStyle(color: context.lq.ink, fontSize: 13),
                ),
                children: [
                  for (final (label, value) in smart)
                    if (value != null)
                      LifeQuestListRow(
                        icon: Icons.check_rounded,
                        title: label,
                        subtitle: value,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
