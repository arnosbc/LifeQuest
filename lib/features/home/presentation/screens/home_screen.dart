import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/dashboard_greeting.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/habit_strip.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/level_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/priority_mission_card.dart';

/// Hoy. Necesita un [HomeBloc] por encima (lo provee el router).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.onNavigate,
  });

  /// Nombre de la sesión; se usa mientras el perfil no tenga uno propio.
  final String userName;
  final ValueChanged<int> onNavigate;

  // Ritmo vertical: 8 entre título y contenido, 24 entre bloques.
  static const _gap = SizedBox(height: 24);
  static const _headingGap = SizedBox(height: 8);

  @override
  Widget build(BuildContext context) => BlocConsumer<HomeBloc, HomeState>(
    listenWhen: (_, state) => state is HomeSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as HomeSuccess).message!),
    builder: (context, state) => switch (state) {
      HomeInitial() || HomeLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.green),
      ),
      HomeFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<HomeBloc>().add(const HomeRequested()),
      ),
      HomeSuccess() => RefreshIndicator(
        color: context.lq.green,
        onRefresh: () => _refresh(context.read<HomeBloc>()),
        child: _content(context, state),
      ),
    },
  );

  static Future<void> _refresh(HomeBloc bloc) {
    bloc.add(const HomeRequested());
    return bloc.stream.firstWhere(
      (state) => state is! HomeSuccess || !state.refreshing,
    );
  }

  Widget _content(BuildContext context, HomeSuccess state) {
    final dashboard = state.dashboard;
    return ListView(
      // Permite deslizar para refrescar aunque el contenido quepa.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        DashboardGreeting(
          userName: dashboard.displayName ?? userName,
          subtitle: _subtitle(dashboard),
          onOpenProfile: () => onNavigate(4),
        ),
        _gap,
        LifeQuestSectionHeading(
          'AHORA',
          action: 'Ver tareas',
          onTap: () => context.go(RoutePaths.missions),
        ),
        _headingGap,
        PriorityMissionCard(
          mission: dashboard.priorityMission,
          onContinue: () => onNavigate(3),
          onCreate: () => context.go(RoutePaths.missions),
        ),
        _gap,
        LifeQuestSectionHeading(
          'HÁBITOS DE HOY',
          action: 'Ver todos',
          onTap: () => onNavigate(2),
        ),
        _headingGap,
        HabitStrip(
          habits: dashboard.habits,
          busyHabitId: state.busyHabitId,
          onComplete: (id) =>
              context.read<HomeBloc>().add(HomeHabitCompleted(id)),
          onOpenHabits: () => onNavigate(2),
        ),
        _gap,
        const LifeQuestSectionHeading('TU PROGRESO'),
        _headingGap,
        LevelCard(dashboard: dashboard),
      ],
    );
  }

  static String _subtitle(HomeDashboard d) {
    final left = (d.missionsTotal - d.missionsDone).clamp(0, d.missionsTotal);
    return switch (left) {
      0 when d.missionsTotal > 0 => 'Cumpliste todo lo de hoy.',
      0 => 'Nada pendiente para hoy.',
      1 => 'Te queda 1 tarea para hoy.',
      _ => 'Te quedan $left tareas para hoy.',
    };
  }
}
