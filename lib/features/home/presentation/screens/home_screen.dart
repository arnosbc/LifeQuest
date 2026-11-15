import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/day_recap.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/habit_strip.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_link_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/how_it_works_sheet.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/nevi_mood.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/next_step_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/progress_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/quick_action.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/task_path.dart';

/// Inicio = Hoy (Main.dc.html con DESIGN.md v2, plan S2): progreso, Siguiente
/// paso, tareas de hoy y hábitos de hoy, todo marcable aquí mismo.
/// Necesita un [HomeBloc] por encima (lo provee el router).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.onNavigate,
    this.unreadNotifications = 0,
  });

  /// Nombre de la sesión; se usa mientras el perfil no tenga uno propio.
  final String userName;
  final ValueChanged<int> onNavigate;

  /// Avisos sin leer para la campana (los trae el router).
  final int unreadNotifications;

  // RF-114: secciones que no caben en la barra inferior.
  static const _tools = [
    (Icons.description_outlined, 'Documentos', RoutePaths.documents),
    (Icons.inbox_outlined, 'Bandeja de ideas', RoutePaths.brainDump),
    (Icons.auto_awesome_outlined, 'Asistente', RoutePaths.rpgenie),
    (Icons.flag_outlined, 'Metas', RoutePaths.goals),
    (Icons.groups_outlined, 'Mentores', RoutePaths.tavern),
    (Icons.history_rounded, 'Actividad', RoutePaths.journal),
    (Icons.redeem_outlined, 'Recompensas', RoutePaths.marketplace),
  ];

  static const _gap = SizedBox(height: 20);

  @override
  Widget build(BuildContext context) => BlocConsumer<HomeBloc, HomeState>(
    listenWhen: (previous, state) =>
        state is HomeSuccess &&
        (state.message != null ||
            // Repaso del día: solo al pasar de «con pendientes» a «todo hecho».
            (previous is HomeSuccess &&
                !dayComplete(previous.dashboard) &&
                dayComplete(state.dashboard))),
    listener: (context, state) {
      final success = state as HomeSuccess;
      switch (success.message) {
        case final message?:
          showLifeQuestMessage(context, message);
        case null:
          showDayRecap(context, success.dashboard);
      }
    },
    builder: (context, state) => switch (state) {
      HomeInitial() || HomeLoading() => Center(
        child: CircularProgressIndicator(color: context.q.ink),
      ),
      HomeFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<HomeBloc>().add(const HomeRequested()),
      ),
      // La barra queda fija arriba mientras el resto se desplaza.
      HomeSuccess(:final dashboard) => Column(
        children: [
          HomeStatusBar(
            dashboard: dashboard,
            onOpenProfile: () => onNavigate(4),
            onExplain: (topic) => showHowItWorks(context, topic),
          ),
          Expanded(
            child: RefreshIndicator(
              color: context.q.ink,
              onRefresh: () => _refresh(context.read<HomeBloc>()),
              child: _content(context, state),
            ),
          ),
        ],
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
    final d = state.dashboard;
    final bloc = context.read<HomeBloc>();
    final next = d.priorityMission;
    return ListView(
      // Permite deslizar para refrescar aunque el contenido quepa.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        QuestlyHero(
          kicker: '¡Qué bueno verte de nuevo!',
          heading: 'Hola, ${d.displayName ?? userName}',
          icon: QIcons.home,
          onAction: () => context.go(RoutePaths.notifications),
          actionLabel: unreadNotifications > 0
              ? 'Avisos, $unreadNotifications sin leer'
              : 'Avisos',
          actionIcon: QIcons.bell,
          badge: unreadNotifications > 0
              ? (unreadNotifications > 9 ? '9+' : '$unreadNotifications')
              : null,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NeviBanner(mood: neviMood(d, DateTime.now())),
              const SizedBox(height: QSpace.m),
              HomeLinkCard(
                icon: QIcons.trophy,
                kicker: 'Desafíos y Liga',
                title: 'Abre los cofres de hoy y sube de división',
                detail: 'Desafíos del día, del mes y tu liga semanal',
                tint: context.q.mustardTint,
                ink: context.q.mustardInk,
                onTap: () => context.push(RoutePaths.challenges),
              ),
              _gap,
              ProgressCard(
                dashboard: d,
                onOpenProfile: () => onNavigate(4),
                onExplain: (topic) => showHowItWorks(context, topic),
              ),
              _gap,
              _SectionTitle(
                'Tu camino de hoy',
                action: next == null ? null : '¿Por qué esta?',
                onAction: () => context.push(RoutePaths.rpgenie),
              ),
              GoalBanner(
                title: d.topGoal?.title,
                progress: d.topGoal?.progress ?? 0,
                onTap: () => d.topGoal == null
                    ? context.go(RoutePaths.stage)
                    : context.push(RoutePaths.goals),
              ),
              const SizedBox(height: QSpace.xl),
              if (next == null) ...[
                NextStepCard(
                  mission: null,
                  busy: false,
                  onFocus: () {},
                  onCreate: () => context.go(RoutePaths.missions),
                ),
                const SizedBox(height: QSpace.l),
              ],
              TaskPath(
                dashboard: d,
                claimingChest: state.claimingChest,
                onFocus: (id) => context.go(RoutePaths.focusOn(id)),
                onClaimChest: () => bloc.add(const HomeChestClaimed()),
              ),
              if (d.mentorTask case final m?) ...[
                const SizedBox(height: QSpace.m),
                HomeLinkCard(
                  icon: QIcons.users,
                  kicker: 'Mentores',
                  title: '${m.mentor} te dejó una tarea guiada',
                  detail: '${m.title} · +${m.xpReward} XP',
                  tint: context.q.riverTint,
                  ink: context.q.riverInk,
                  onTap: () => context.push(RoutePaths.task(m.id)),
                ),
              ],
              if (d.inboxCount > 0) ...[
                const SizedBox(height: QSpace.m),
                HomeLinkCard(
                  icon: QIcons.inbox,
                  kicker: 'Bandeja de ideas',
                  title: d.inboxCount == 1
                      ? '1 idea espera que la ordenes'
                      : '${d.inboxCount} ideas esperan que las ordenes',
                  detail: 'Vacía tu cabeza aquí y decide después',
                  tint: context.q.mustardTint,
                  ink: context.q.mustardInk,
                  onTap: () => context.push(RoutePaths.brainDump),
                ),
              ],
              _gap,
              _SectionTitle(
                'Hábitos de hoy',
                action: _streakLabel(d),
                onAction: () => onNavigate(2),
              ),
              HabitStrip(
                habits: d.habits,
                busyHabitId: state.busyHabitId,
                onComplete: (id) => bloc.add(HomeHabitCompleted(id)),
                onOpenHabits: () => onNavigate(2),
              ),
              _gap,
              const _SectionTitle('Más herramientas'),
              for (var i = 0; i < _tools.length; i += 3) ...[
                if (i > 0) const SizedBox(height: QSpace.s),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (j, (icon, label, path))
                          in _tools.skip(i).take(3).indexed) ...[
                        if (j > 0) const SizedBox(width: QSpace.s),
                        Expanded(
                          child: QuickAction(
                            icon: icon,
                            label: label,
                            vertical: true,
                            onTap: () => context.push(path),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _streakLabel(HomeDashboard dashboard) =>
      switch (dashboard.streakDays) {
        0 => 'Ver todos',
        1 => 'Racha de 1 día',
        final days => 'Racha de $days días',
      };
}

/// Nevi según el día ([neviMood]) sobre las montañas, con su mensaje a la izquierda.
class _NeviBanner extends StatelessWidget {
  const _NeviBanner({required this.mood});

  final (String, String) mood;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final (pose, message) = mood;
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: q.tint,
        borderRadius: BorderRadius.circular(QRadius.card),
        boxShadow: qSolidShadow(q.cardShadow),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 170,
            child: ShaderMask(
              shaderCallback: _fadeLeft,
              blendMode: BlendMode.dstIn,
              child: LifeQuestLandscape(alignment: Alignment(0, .6)),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 0,
            child: ExcludeSemantics(child: MascotPose(pose: pose, size: 92)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 108, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                style: QText.label(q.text).copyWith(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // El paisaje se funde con el fondo hacia el texto.
  static Shader _fadeLeft(Rect r) => const LinearGradient(
    colors: [Color(0x00000000), Color(0xFF000000)],
    stops: [0, .45],
  ).createShader(r);
}

/// Título de bloque (title3) con un enlace opcional a la derecha.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.only(bottom: QSpace.s),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: QText.title3(q.text)),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: q.ink,
                minimumSize: const Size(48, QSize.minTap),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(
                action!,
                style: QText.label(q.ink).copyWith(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
