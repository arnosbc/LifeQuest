import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/daily_chest_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/habit_strip.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/home_link_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/how_it_works_sheet.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/next_step_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/progress_card.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/quick_action.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/today_list.dart';

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
    listenWhen: (_, state) => state is HomeSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as HomeSuccess).message!),
    builder: (context, state) => switch (state) {
      HomeInitial() || HomeLoading() => Center(
        child: CircularProgressIndicator(color: context.q.ink),
      ),
      HomeFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<HomeBloc>().add(const HomeRequested()),
      ),
      HomeSuccess() => RefreshIndicator(
        color: context.q.ink,
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
    final d = state.dashboard;
    final bloc = context.read<HomeBloc>();
    final next = d.priorityMission;
    final today = [
      for (final t in d.todayTasks)
        if (t.id != next?.id) t,
    ];
    final busyNext = next != null && state.busyTaskId == next.id;
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
              const _MotivationBanner(),
              _gap,
              _SectionTitle(
                'Tus metas',
                action: 'Ver todas',
                onAction: () => context.push(RoutePaths.goals),
              ),
              if (d.topGoal case final g?) ...[
                TopGoalCard(
                  title: g.title,
                  progress: g.progress,
                  onTap: () => context.push(RoutePaths.goals),
                ),
                const SizedBox(height: QSpace.m),
              ],
              QuestlyButton(
                label: 'Agregar meta',
                icon: QIcons.plus,
                onPressed: () => context.go(RoutePaths.stage),
              ),
              _gap,
              ProgressCard(
                dashboard: d,
                onOpenProfile: () => onNavigate(4),
                onExplain: (topic) => showHowItWorks(context, topic),
              ),
              _gap,
              _SectionTitle(
                'Siguiente paso',
                action: next == null ? null : '¿Por qué esta?',
                onAction: () => context.push(RoutePaths.rpgenie),
              ),
              NextStepCard(
                mission: next,
                busy: busyNext,
                onFocus: () => context.go(RoutePaths.focusOn(next!.id)),
                onCreate: () => context.go(RoutePaths.missions),
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
              if (today.isNotEmpty) ...[
                _gap,
                _SectionTitle(
                  'Hoy',
                  action: 'Ver todas',
                  onAction: () => context.go(RoutePaths.missions),
                ),
                TodayList(
                  tasks: today,
                  busyTaskId: state.busyTaskId,
                  onFocus: (id) => context.go(RoutePaths.focusOn(id)),
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
              const SizedBox(height: QSpace.m),
              DailyChestCard(
                chest: d.chest,
                busy: state.claimingChest,
                onClaim: () => bloc.add(const HomeChestClaimed()),
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

/// «Cada pequeño paso también es progreso.» con montañas a la derecha.
class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner();

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      height: 96,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 150, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Cada pequeño paso también es progreso.',
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
