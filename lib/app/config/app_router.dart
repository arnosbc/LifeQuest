import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/app_shell.dart';
import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/register_screen.dart';
import 'package:proyecto_movil/features/dungeon/presentation/screens/dungeon_screen.dart';
import 'package:proyecto_movil/features/goals/presentation/screens/goals_screen.dart';
import 'package:proyecto_movil/features/habits/presentation/screens/habits_screen.dart';
import 'package:proyecto_movil/features/home/presentation/screens/home_screen.dart';
import 'package:proyecto_movil/features/journal/presentation/screens/journal_screen.dart';
import 'package:proyecto_movil/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:proyecto_movil/features/missions/presentation/screens/missions_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/appearance_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/help_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/notifications_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/profile_screen.dart';
import 'package:proyecto_movil/features/rpgenie/presentation/screens/rpgenie_screen.dart';
import 'package:proyecto_movil/features/settings/presentation/screens/settings_screen.dart';
import 'package:proyecto_movil/features/stage/presentation/screens/stage_screen.dart';
import 'package:proyecto_movil/features/tavern/presentation/screens/tavern_screen.dart';

/// Rutas de la app. Aquí se componen las features: cada pantalla recibe por
/// constructor lo que viene de otra (nombre de usuario, cerrar sesión, navegar),
/// así ninguna feature importa a otra.
GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  initialLocation: RoutePaths.home,
  refreshListenable: _BlocRefresh(authBloc.stream),
  redirect: (context, state) {
    final signedIn = authBloc.state is AuthSuccess;
    final atAuth =
        state.matchedLocation == RoutePaths.login ||
        state.matchedLocation == RoutePaths.register;
    if (!signedIn && !atAuth) return RoutePaths.login;
    if (signedIn && atAuth) return RoutePaths.home;
    return null;
  },
  routes: [
    GoRoute(
      path: RoutePaths.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: RoutePaths.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    StatefulShellRoute.indexedStack(
      // shortcut: estas pantallas aún usan colores fijos del tema claro; quitar
      // lightOnly cuando se migren a context.lq.
      builder: (context, state, shell) =>
          LifeQuestTheme.lightOnly(AppShell(navigationShell: shell)),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => HomeScreen(
                userName: _userName(context),
                onNavigate: (tab) =>
                    StatefulNavigationShell.of(context).goBranch(tab),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.missions,
              builder: (context, state) => const MissionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.dungeon,
              builder: (context, state) => const DungeonScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.habits,
              builder: (context, state) => const HabitsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.profile,
              builder: (context, state) => ProfileScreen(
                userName: _userName(context),
                onOpenNotifications: () => context.go(RoutePaths.notifications),
                onOpenHelp: () => context.go(RoutePaths.help),
                onOpenAppearance: () => context.go(RoutePaths.appearance),
                onOpenSettings: () => context.push(RoutePaths.settings),
              ),
              routes: [
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) =>
                      NotificationsScreen(onBack: () => context.pop()),
                ),
                GoRoute(
                  path: 'help',
                  builder: (context, state) =>
                      HelpScreen(onBack: () => context.pop()),
                ),
                GoRoute(
                  path: 'appearance',
                  builder: (context, state) =>
                      AppearanceScreen(onBack: () => context.pop()),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.settings,
      builder: (context, state) => LifeQuestTheme.lightOnly(
        SettingsScreen(
          userName: _userName(context),
          onBack: () => context.pop(),
          onSignOut: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
        ),
      ),
    ),
    _section(RoutePaths.rpgenie, const RpgenieScreen()),
    _section(RoutePaths.stage, const StageScreen()),
    _section(RoutePaths.journal, const JournalScreen()),
    _section(RoutePaths.goals, const GoalsScreen()),
    _section(RoutePaths.tavern, const TavernScreen()),
    _section(RoutePaths.marketplace, const MarketplaceScreen()),
  ],
);

/// Secciones del menú (RF-114) que no caben en la barra inferior: pantalla
/// completa con botón de volver.
GoRoute _section(String path, Widget screen) => GoRoute(
  path: path,
  builder: (context, state) => LifeQuestTheme.lightOnly(
    Scaffold(
      backgroundColor: LifeQuestColors.background,
      appBar: AppBar(backgroundColor: LifeQuestColors.background),
      body: SafeArea(child: screen),
    ),
  ),
);

String _userName(BuildContext context) =>
    switch (context.read<AuthBloc>().state) {
      AuthSuccess(:final user) => user.displayName,
      _ => 'Héroe',
    };

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
