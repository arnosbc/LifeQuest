import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/app_shell.dart';
import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/check_email_screen.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/register_screen.dart';
import 'package:proyecto_movil/features/dungeon/presentation/screens/dungeon_screen.dart';
import 'package:proyecto_movil/features/goals/presentation/screens/goals_screen.dart';
import 'package:proyecto_movil/features/habits/presentation/screens/habits_screen.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/screens/home_screen.dart';
import 'package:proyecto_movil/features/journal/presentation/screens/journal_screen.dart';
import 'package:proyecto_movil/features/marketplace/presentation/screens/marketplace_screen.dart';
import 'package:proyecto_movil/features/missions/presentation/screens/missions_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/appearance_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/help_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/notifications_screen.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/profile_screen.dart';
import 'package:proyecto_movil/features/rpgenie/presentation/screens/rpgenie_screen.dart';
import 'package:proyecto_movil/features/settings/presentation/screens/settings_screen.dart';
import 'package:proyecto_movil/features/stage/presentation/screens/stage_screen.dart';
import 'package:proyecto_movil/features/tavern/presentation/screens/tavern_screen.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Rutas de la app. Aquí se componen las features: cada pantalla recibe por
/// constructor lo que viene de otra (nombre de usuario, cerrar sesión, navegar),
/// así ninguna feature importa a otra.
GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  initialLocation: RoutePaths.home,
  refreshListenable: _BlocRefresh(authBloc.stream),
  redirect: (context, state) {
    final signedIn = authBloc.state is AuthSuccess;
    final atAuth = const [
      RoutePaths.login,
      RoutePaths.register,
      RoutePaths.checkEmail,
    ].contains(state.matchedLocation);
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
    GoRoute(
      path: RoutePaths.checkEmail,
      // Sin datos del registro (p. ej. al restaurar la app) no hay qué mostrar.
      redirect: (context, state) => state.extra is AuthEmailConfirmationRequired
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
      // shortcut: salvo las rutas de _themedPaths, estas pantallas usan colores
      // fijos del tema claro; añadir cada ruta al migrarla a context.lq.
      // Siempre se envuelve en Theme (solo cambia `data`) para no reconstruir
      // las ramas y perder su estado al cambiar de pestaña.
      builder: (context, state, shell) => Theme(
        data: _themedPaths.contains(state.uri.path)
            ? Theme.of(context)
            : LifeQuestTheme.light,
        child: AppShell(navigationShell: shell),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => BlocProvider(
                create: (_) => sl<HomeBloc>()..add(const HomeRequested()),
                child: HomeScreen(
                  userName: _userName(context),
                  onNavigate: (tab) =>
                      StatefulNavigationShell.of(context).goBranch(tab),
                ),
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
              builder: (context, state) => BlocProvider(
                create: (_) => sl<ProfileBloc>()..add(const ProfileRequested()),
                child: ProfileScreen(
                  userName: _userName(context),
                  onOpenNotifications: () =>
                      context.go(RoutePaths.notifications),
                  onOpenHelp: () => context.go(RoutePaths.help),
                  onOpenJournal: () => context.push(RoutePaths.journal),
                  onOpenMarketplace: () => context.push(RoutePaths.marketplace),
                  onOpenSettings: () => context.push(RoutePaths.settings),
                ),
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
          onOpenAppearance: () => context.push(RoutePaths.appearance),
        ),
      ),
      routes: [
        // Sigue el tema (está en _themedPaths), fuera de lightOnly.
        GoRoute(
          path: 'appearance',
          builder: (context, state) =>
              AppearanceScreen(onBack: () => context.pop()),
        ),
      ],
    ),
    _section(RoutePaths.rpgenie, const RpgenieScreen()),
    _section(RoutePaths.stage, const StageScreen()),
    _section(RoutePaths.journal, const JournalScreen()),
    _section(RoutePaths.goals, const GoalsScreen()),
    _section(RoutePaths.tavern, const TavernScreen()),
    _section(RoutePaths.marketplace, const MarketplaceScreen()),
  ],
);

/// Rutas de la barra inferior ya migradas a `context.lq` (siguen el tema).
const _themedPaths = {RoutePaths.profile, RoutePaths.appearance};

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
