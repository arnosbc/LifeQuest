import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/rpgenie/domain/entities/current_mission.dart';
import 'package:proyecto_movil/features/rpgenie/presentation/blocs/rpgenie_bloc.dart';

/// RPGenie v1: la Misión actual por reglas (RF-097). Necesita un
/// [RpgenieBloc] por encima.
class RpgenieScreen extends StatelessWidget {
  const RpgenieScreen({super.key, required this.onStartFocus});

  /// Abre la Mazmorra para hacer la misión con foco.
  final VoidCallback onStartFocus;

  @override
  Widget build(BuildContext context) => BlocConsumer<RpgenieBloc, RpgenieState>(
    listenWhen: (_, s) => s is RpgenieSuccess && s.message != null,
    listener: (context, s) =>
        showLifeQuestMessage(context, (s as RpgenieSuccess).message!),
    builder: (context, state) => switch (state) {
      RpgenieInitial() || RpgenieLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      RpgenieFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () =>
            context.read<RpgenieBloc>().add(const RpgenieRequested()),
      ),
      RpgenieSuccess() => RefreshIndicator(
        color: context.lq.deepGreen,
        onRefresh: () async {
          final bloc = context.read<RpgenieBloc>()
            ..add(const RpgenieRequested());
          await bloc.stream.firstWhere(
            (s) => s is! RpgenieSuccess || !s.refreshing,
          );
        },
        child: _content(context, state),
      ),
    },
  );

  Widget _content(BuildContext context, RpgenieSuccess state) {
    final bloc = context.read<RpgenieBloc>();
    final board = state.board;
    final mission = board.mission;
    return LifeQuestPage(
      title: 'RPGenie',
      subtitle: 'Tu siguiente paso, elegido para ti.',
      children: [
        const LifeQuestSectionHeading('MISIÓN ACTUAL'),
        const SizedBox(height: 7),
        if (mission == null)
          LifeQuestListRow(
            icon: Icons.celebration_outlined,
            title: board.openCount == 0
                ? 'No tienes misiones abiertas'
                : 'Apartaste todas por ahora',
            subtitle: board.openCount == 0
                ? 'Captura algo nuevo en Stage cuando quieras.'
                : 'Descansa o vuelve a verlas cuando te sientas listo.',
          )
        else
          LifeQuestSurface(
            color: context.lq.softGreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const LifeQuestIconTile(Icons.auto_awesome),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        mission.title,
                        style: TextStyle(
                          color: context.lq.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _reason(mission),
                  style: TextStyle(color: context.lq.ink, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    '+${mission.xpReward} XP · +${mission.coinReward} 🪙',
                    ?(mission.goalTitle ??
                        mission.projectTitle ??
                        mission.skillName),
                  ].join(' · '),
                  style: TextStyle(color: context.lq.muted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: state.busy
                              ? null
                              : () => bloc.add(
                                  CurrentMissionCompleted(mission.id),
                                ),
                          child: const Text('¡Hecha!'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: state.busy ? null : onStartFocus,
                          child: const Text('A la Mazmorra'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: state.busy
                      ? null
                      : () => bloc.add(MissionSkipped(mission.id)),
                  child: const Text('Ahora no'),
                ),
              ],
            ),
          ),
        if (board.skippedCount > 0)
          TextButton(
            onPressed: state.busy ? null : () => bloc.add(const SkipsCleared()),
            child: Text('Volver a ver las ${board.skippedCount} apartadas'),
          ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('CÓMO ELIJO TU MISIÓN'),
        const SizedBox(height: 7),
        // RF-097: crítico → urgencia 🔴 > 🟡 > 🟢 → fecha límite más próxima.
        const LifeQuestListRow(
          icon: Icons.priority_high_rounded,
          title: '1. Lo crítico primero',
          subtitle: 'Lo que vence en menos de 24 horas.',
        ),
        const LifeQuestListRow(
          icon: Icons.traffic_outlined,
          title: '2. Después, la prioridad',
          subtitle: '🔴 alta, luego 🟡 media y 🟢 baja.',
        ),
        const LifeQuestListRow(
          icon: Icons.event_outlined,
          title: '3. Por último, la fecha',
          subtitle: 'La fecha límite más próxima va primero.',
        ),
      ],
    );
  }

  static String _reason(CurrentMission m) => switch (m.reason) {
    MissionReason.critical =>
      m.dueDate != null && m.dueDate!.isBefore(DateTime.now())
          ? '▲ Su fecha ya pasó: aún puedes cerrarla hoy.'
          : '▲ Vence pronto: ${LifeQuestDates.dayTime(m.dueDate!)}.',
    MissionReason.high => '● Es de prioridad alta.',
    MissionReason.due =>
      '○ Su fecha es la más próxima: ${LifeQuestDates.day(m.dueDate!)}.',
    MissionReason.next => '○ Es la que llevas más tiempo esperando.',
  };
}
