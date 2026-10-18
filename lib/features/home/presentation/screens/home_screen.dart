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
import 'package:proyecto_movil/features/home/presentation/widgets/quick_action.dart';

/// Inicio. Necesita un [HomeBloc] por encima (lo provee el router).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.onNavigate,
  });

  /// Nombre de la sesión; se usa mientras el perfil no tenga uno propio.
  final String userName;
  final ValueChanged<int> onNavigate;

  static const _sections = [
    (Icons.auto_awesome_outlined, 'RPGenie', RoutePaths.rpgenie),
    (Icons.dashboard_outlined, 'Stage · P.A.R.A.', RoutePaths.stage),
    (Icons.auto_stories_outlined, 'Diario', RoutePaths.journal),
    (Icons.flag_outlined, 'Objetivos', RoutePaths.goals),
    (Icons.sports_bar_outlined, 'Taverna', RoutePaths.tavern),
    (Icons.storefront_outlined, 'Marketplace', RoutePaths.marketplace),
  ];

  // Ritmo vertical: 8 entre título y contenido, 24 entre bloques.
  static const _gap = SizedBox(height: 24);
  static const _headingGap = SizedBox(height: 8);

  @override
  Widget build(BuildContext context) => BlocConsumer<HomeBloc, HomeState>(
    listenWhen: (_, state) => state is HomeSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as HomeSuccess).message!),
    builder: (context, state) => switch (state) {
      HomeInitial() || HomeLoading() => const Center(
        child: CircularProgressIndicator(color: LifeQuestColors.deepGreen),
      ),
      HomeFailure(:final message) => _ErrorView(
        message: message,
        onRetry: () => context.read<HomeBloc>().add(const HomeRequested()),
      ),
      HomeSuccess() => RefreshIndicator(
        color: LifeQuestColors.deepGreen,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        DashboardGreeting(
          userName: dashboard.displayName ?? userName,
          onOpenProfile: () => onNavigate(4),
        ),
        const SizedBox(height: 20),
        // La misión va primero: es la única acción primaria de la pantalla.
        LifeQuestSectionHeading(
          'MISIÓN PRIORITARIA',
          action: 'Ver todas',
          onTap: () => onNavigate(1),
        ),
        _headingGap,
        PriorityMissionCard(
          mission: dashboard.priorityMission,
          onContinue: () => onNavigate(1),
          onCreate: () => onNavigate(1),
        ),
        _gap,
        const LifeQuestSectionHeading('TU HÉROE'),
        _headingGap,
        LevelCard(dashboard: dashboard),
        _gap,
        LifeQuestSectionHeading(
          'HÁBITOS DE HOY',
          action: _streakLabel(dashboard),
          onTap: () => onNavigate(3),
        ),
        _headingGap,
        HabitStrip(
          habits: dashboard.habits,
          busyHabitId: state.busyHabitId,
          onComplete: (id) =>
              context.read<HomeBloc>().add(HomeHabitCompleted(id)),
          onOpenHabits: () => onNavigate(3),
        ),
        _gap,
        const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
        _headingGap,
        _row([
          QuickAction(
            icon: Icons.add_box_outlined,
            label: 'Nueva tarea',
            onTap: () => onNavigate(1),
          ),
          QuickAction(
            icon: Icons.timer_outlined,
            label: 'Modo focus',
            onTap: () => onNavigate(2),
          ),
        ]),
        const SizedBox(height: 8),
        _row([
          QuickAction(
            icon: Icons.monitor_heart_outlined,
            label: 'Registrar hábito',
            onTap: () => onNavigate(3),
          ),
          QuickAction(
            icon: Icons.tune_rounded,
            label: 'Game Master',
            onTap: () => context.push(RoutePaths.settings),
          ),
        ]),
        _gap,
        // RF-114: secciones que no caben en la barra inferior.
        const LifeQuestSectionHeading('EXPLORA EL REINO'),
        for (var i = 0; i < _sections.length; i += 3) ...[
          _headingGap,
          _row([
            for (final section in _sections.skip(i).take(3))
              _sectionAction(context, section),
          ]),
        ],
      ],
    );
  }

  static String _streakLabel(HomeDashboard dashboard) =>
      switch (dashboard.streakDays) {
        0 => 'Ver todos',
        1 => 'Racha de 1 día',
        final days => 'Racha de $days días',
      };

  Widget _row(List<Widget> children) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    ),
  );

  Widget _sectionAction(
    BuildContext context,
    (IconData, String, String) section,
  ) {
    final (icon, label, path) = section;
    return QuickAction(
      icon: icon,
      label: label,
      vertical: true,
      onTap: () => context.push(path),
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
          const LifeQuestIconTile(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: LifeQuestColors.ink, fontSize: 15),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Reintentar'),
            style: FilledButton.styleFrom(
              backgroundColor: LifeQuestColors.deepGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    ),
  );
}
