import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/app_shell.dart';
import 'package:proyecto_movil/app/config/design_preview_screen.dart';
import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/check_email_screen.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/register_screen.dart';
import 'package:proyecto_movil/features/brain_dump/presentation/blocs/brain_dump_bloc.dart';
import 'package:proyecto_movil/features/brain_dump/presentation/screens/brain_dump_screen.dart';
import 'package:proyecto_movil/features/dungeon/presentation/blocs/dungeon_bloc.dart';
import 'package:proyecto_movil/features/dungeon/presentation/screens/dungeon_screen.dart';
import 'package:proyecto_movil/features/goals/presentation/blocs/goals_bloc.dart';
import 'package:proyecto_movil/features/goals/presentation/screens/goals_screen.dart';
import 'package:proyecto_movil/features/habits/presentation/blocs/habits_bloc.dart';
import 'package:proyecto_movil/features/habits/presentation/screens/habits_screen.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/screens/home_screen.dart';
import 'package:proyecto_movil/features/inventory/presentation/blocs/inventory_bloc.dart';
import 'package:proyecto_movil/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:proyecto_movil/features/journal/presentation/blocs/journal_bloc.dart';
import 'package:proyecto_movil/features/journal/presentation/screens/journal_screen.dart';
import 'package:proyecto_movil/features/marketplace/presentation/blocs/marketplace_bloc.dart';
import 'package:proyecto_movil/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:proyecto_movil/features/missions/presentation/screens/missions_screen.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/appearance_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/help_screen.dart';
import 'package:proyecto_movil/features/notifications/presentation/blocs/notifications_bloc.dart';
import 'package:proyecto_movil/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/profile_screen.dart';
import 'package:proyecto_movil/features/rpgenie/presentation/blocs/rpgenie_bloc.dart';
import 'package:proyecto_movil/features/rpgenie/presentation/screens/rpgenie_screen.dart';
import 'package:proyecto_movil/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:proyecto_movil/features/settings/presentation/screens/settings_screen.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';
import 'package:proyecto_movil/features/stage/presentation/screens/stage_screen.dart';
import 'package:proyecto_movil/features/stats/presentation/blocs/stats_bloc.dart';
import 'package:proyecto_movil/features/stats/presentation/screens/stats_screen.dart';
import 'package:proyecto_movil/features/tavern/presentation/blocs/tavern_bloc.dart';
import 'package:proyecto_movil/features/tavern/presentation/screens/tavern_screen.dart';
import 'package:proyecto_movil/features/vision/presentation/blocs/vision_bloc.dart';
import 'package:proyecto_movil/features/vision/presentation/screens/vision_screen.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Rutas de la app. Aquí se componen las features: cada pantalla recibe por
/// constructor lo que viene de otra (nombre de usuario, cerrar sesión, navegar),
/// así ninguna feature importa a otra.
GoRouter createAppRouter(AuthBloc authBloc, OnboardingBloc onboardingBloc) {
  // Ruta visible dentro de la barra inferior: al volver a una pestaña, recarga.
  final shellLocation = ValueNotifier<String>(RoutePaths.home);
  return GoRouter(
    initialLocation: RoutePaths.home,
    refreshListenable: Listenable.merge([
      _BlocRefresh(authBloc.stream),
      _BlocRefresh(onboardingBloc.stream),
    ]),
    redirect: (context, state) {
      final signedIn = authBloc.state is AuthSuccess;
      final location = state.matchedLocation;
      final atAuth = const [
        RoutePaths.login,
        RoutePaths.register,
        RoutePaths.checkEmail,
      ].contains(location);
      if (!signedIn) return atAuth ? null : RoutePaths.login;
      // Mientras se consulta también va al Onboarding (muestra un indicador),
      // así quien lo tiene pendiente nunca ve Inicio antes (FR-001).
      final onboarding = onboardingBloc.state is! OnboardingNotNeeded;
      if (onboarding) {
        return location == RoutePaths.onboarding ? null : RoutePaths.onboarding;
      }
      if (atAuth || location == RoutePaths.onboarding) return RoutePaths.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.checkEmail,
        // Sin datos del registro (p. ej. al restaurar la app) no hay qué mostrar.
        redirect: (context, state) =>
            state.extra is AuthEmailConfirmationRequired
            ? null
            : RoutePaths.login,
        builder: (context, state) {
          final pending = state.extra! as AuthEmailConfirmationRequired;
          return CheckEmailScreen(
            username: pending.username,
            email: pending.email,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          shellLocation.value = state.uri.path;
          return AppShell(navigationShell: shell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<HomeBloc>()..add(const HomeRequested()),
                  child: _ReloadOnShow(
                    location: shellLocation,
                    path: RoutePaths.home,
                    onShown: (c) =>
                        c.read<HomeBloc>().add(const HomeRequested()),
                    child: HomeScreen(
                      userName: _userName(context),
                      onNavigate: (tab) =>
                          StatefulNavigationShell.of(context).goBranch(tab),
                    ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.stage,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<StageBloc>()..add(const StageRequested()),
                  child: _ReloadOnShow(
                    location: shellLocation,
                    path: RoutePaths.stage,
                    onShown: (c) =>
                        c.read<StageBloc>().add(const StageRequested()),
                    child: StageScreen(
                      onOpenMissions: () => context.go(RoutePaths.missions),
                    ),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'missions',
                    builder: (context, state) => Scaffold(
                      backgroundColor: context.lq.background,
                      appBar: AppBar(backgroundColor: context.lq.background),
                      body: BlocProvider(
                        create: (_) =>
                            sl<MissionsBloc>()..add(const MissionsRequested()),
                        child: MissionsScreen(
                          onStartFocus: () => context.go(RoutePaths.dungeon),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.habits,
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<HabitsBloc>()..add(const HabitsRequested()),
                  child: _ReloadOnShow(
                    location: shellLocation,
                    path: RoutePaths.habits,
                    onShown: (c) =>
                        c.read<HabitsBloc>().add(const HabitsRequested()),
                    child: const HabitsScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dungeon,
                builder: (context, state) => BlocProvider(
                  create: (_) =>
                      sl<DungeonBloc>()..add(const DungeonRequested()),
                  child: _ReloadOnShow(
                    location: shellLocation,
                    path: RoutePaths.dungeon,
                    onShown: (c) =>
                        c.read<DungeonBloc>().add(const DungeonRequested()),
                    // La Mazmorra siempre es oscura (CLAUDE.md §14).
                    child:
                        BlocSelector<
                          AppearanceBloc,
                          AppearanceState,
                          ThemeRealm
                        >(
                          selector: (state) => state.realm,
                          builder: (context, realm) => Theme(
                            data: LifeQuestTheme.build(
                              questlyRealmOf(realm),
                              dark: true,
                            ),
                            child: Builder(
                              builder: (context) => ColoredBox(
                                color: context.lq.background,
                                child: const DungeonScreen(),
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => BlocProvider(
                  create: (_) =>
                      sl<ProfileBloc>()..add(const ProfileRequested()),
                  child: _ReloadOnShow(
                    location: shellLocation,
                    path: RoutePaths.profile,
                    onShown: (c) =>
                        c.read<ProfileBloc>().add(const ProfileRequested()),
                    child: ProfileScreen(
                      userName: _userName(context),
                      onOpenNotifications: () =>
                          context.go(RoutePaths.notifications),
                      onOpenHelp: () => context.go(RoutePaths.help),
                      onOpenJournal: () => context.push(RoutePaths.journal),
                      onOpenMarketplace: () =>
                          context.push(RoutePaths.marketplace),
                      onOpenSettings: () => context.push(RoutePaths.settings),
                      onOpenStats: () => context.push(RoutePaths.stats),
                      onOpenVision: () => context.push(RoutePaths.vision),
                      onOpenInventory: () => context.push(RoutePaths.inventory),
                    ),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => BlocProvider(
                      create: (_) =>
                          sl<NotificationsBloc>()
                            ..add(const NotificationsRequested()),
                      child: NotificationsScreen(onBack: () => context.pop()),
                    ),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) =>
                        HelpScreen(onBack: () => context.pop()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: BlocProvider(
              create: (_) => sl<SettingsBloc>()..add(const SettingsRequested()),
              child: SettingsScreen(
                userName: _userName(context),
                onBack: () => context.pop(),
                onSignOut: () =>
                    context.read<AuthBloc>().add(const LogoutRequested()),
                onOpenAppearance: () => context.push(RoutePaths.appearance),
              ),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (context, state) => Scaffold(
              body: SafeArea(
                child: AppearanceScreen(
                  onBack: () => context.pop(),
                  onOpenDesignPreview: kDebugMode
                      ? () => context.push(RoutePaths.designPreview)
                      : null,
                ),
              ),
            ),
          ),
          // Galería de componentes Questly: solo en desarrollo.
          if (kDebugMode)
            GoRoute(
              path: 'diseno',
              builder: (context, state) => const DesignPreviewScreen(),
            ),
        ],
      ),
      _section(
        RoutePaths.rpgenie,
        (context) => BlocProvider(
          create: (_) => sl<RpgenieBloc>()..add(const RpgenieRequested()),
          child: RpgenieScreen(
            onStartFocus: () => context.go(RoutePaths.dungeon),
          ),
        ),
      ),
      _section(
        RoutePaths.journal,
        (context) => BlocProvider(
          create: (_) => sl<JournalBloc>()..add(const JournalRequested()),
          child: const JournalScreen(),
        ),
      ),
      _section(
        RoutePaths.goals,
        (context) => BlocProvider(
          create: (_) => sl<GoalsBloc>()..add(const GoalsRequested()),
          child: GoalsScreen(onCreateGoal: () => context.go(RoutePaths.stage)),
        ),
      ),
      _section(
        RoutePaths.tavern,
        (context) => BlocProvider(
          create: (_) => sl<TavernBloc>()..add(const TavernRequested()),
          child: const TavernScreen(),
        ),
      ),
      _section(
        RoutePaths.marketplace,
        (context) => BlocProvider(
          create: (_) =>
              sl<MarketplaceBloc>()..add(const MarketplaceRequested()),
          child: const MarketplaceScreen(),
        ),
      ),
      _section(
        RoutePaths.brainDump,
        (context) => BlocProvider(
          create: (_) => sl<BrainDumpBloc>()..add(const BrainDumpRequested()),
          child: BrainDumpScreen(
            onCreateGoal: () => context.go(RoutePaths.stage),
          ),
        ),
      ),
      _section(
        RoutePaths.stats,
        (context) => BlocProvider(
          create: (_) => sl<StatsBloc>()..add(const StatsRequested()),
          child: const StatsScreen(),
        ),
      ),
      _section(
        RoutePaths.vision,
        (context) => BlocProvider(
          create: (_) => sl<VisionBloc>()..add(const VisionRequested()),
          child: const VisionScreen(),
        ),
      ),
      _section(
        RoutePaths.inventory,
        (context) => BlocProvider(
          create: (_) => sl<InventoryBloc>()..add(const InventoryRequested()),
          child: InventoryScreen(
            onOpenMarketplace: () => context.push(RoutePaths.marketplace),
          ),
        ),
      ),
    ],
  );
}

/// Secciones del menú (RF-114) que no caben en la barra inferior: pantalla
/// completa con botón de volver. Siguen el tema claro/oscuro (`context.lq`).
GoRoute _section(String path, WidgetBuilder screen) => GoRoute(
  path: path,
  builder: (context, state) => Scaffold(
    backgroundColor: context.lq.background,
    appBar: AppBar(backgroundColor: context.lq.background),
    body: SafeArea(child: screen(context)),
  ),
);

String _userName(BuildContext context) =>
    switch (context.read<AuthBloc>().state) {
      AuthSuccess(:final user) => user.displayName,
      _ => 'Héroe',
    };

/// Las pestañas viven todo el tiempo (indexedStack): sin esto, lo que cambia en
/// otra (XP, vida, Monedas, misiones) no se vería hasta reiniciar la app.
/// Al volver a [path] pide los datos otra vez, sin cargador.
class _ReloadOnShow extends StatefulWidget {
  const _ReloadOnShow({
    required this.location,
    required this.path,
    required this.onShown,
    required this.child,
  });

  final ValueListenable<String> location;
  final String path;
  final void Function(BuildContext context) onShown;
  final Widget child;

  @override
  State<_ReloadOnShow> createState() => _ReloadOnShowState();
}

class _ReloadOnShowState extends State<_ReloadOnShow> {
  @override
  void initState() {
    super.initState();
    widget.location.addListener(_onLocation);
  }

  void _onLocation() {
    if (mounted && widget.location.value == widget.path) {
      widget.onShown(context);
    }
  }

  @override
  void dispose() {
    widget.location.removeListener(_onLocation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Avisa al router cada vez que cambia la sesión para reevaluar `redirect`.
class _BlocRefresh extends ChangeNotifier {
  _BlocRefresh(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
