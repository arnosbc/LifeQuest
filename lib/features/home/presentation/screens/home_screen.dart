import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/day_sheet.dart';

/// Hoy. Necesita un [HomeBloc] por encima (lo provee el router).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.onNavigate,
    required this.onStartFocus,
    required this.onPlanDay,
    required this.onReplan,
    required this.onCapture,
    required this.onVoice,
  });

  /// Nombre de la sesión; se usa mientras el perfil no tenga uno propio.
  final String userName;
  final ValueChanged<int> onNavigate;

  /// Abre Foco con la tarea en la mochila.
  final ValueChanged<String> onStartFocus;
  final VoidCallback onPlanDay;
  final VoidCallback onReplan;
  final VoidCallback onCapture;
  final VoidCallback onVoice;

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

  Widget _content(BuildContext context, HomeSuccess state) => LayoutBuilder(
    builder: (context, box) => ListView(
      // Permite deslizar para refrescar aunque el contenido quepa.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      children: [
        DaySheet(
          dashboard: state.dashboard,
          now: DateTime.now(),
          busyHabitId: state.busyHabitId,
          // Encuadernación (≈35) y margen de arriba: la hoja llega a la barra.
          minHeight: box.maxHeight - 47,
          onStartFocus: onStartFocus,
          onPlanDay: onPlanDay,
          onReplan: onReplan,
          onCapture: onCapture,
          onVoice: onVoice,
          onConnectCalendar: () =>
              context.read<HomeBloc>().add(const HomeCalendarConnected()),
          onCreateTask: () => context.go(RoutePaths.missions),
          onOpenHabits: () => onNavigate(2),
          onCompleteHabit: (id) =>
              context.read<HomeBloc>().add(HomeHabitCompleted(id)),
          onScheduleTask: (id, at) =>
              context.read<HomeBloc>().add(HomeTaskScheduled(id, at)),
        ),
      ],
    ),
  );
}
