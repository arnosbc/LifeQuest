import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/app_router.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';

/// Raíz de la app: provee la sesión (AuthBloc) y el tema (AppearanceBloc) por
/// encima del router.
class App extends StatefulWidget {
  const App({super.key, required this.authBloc, required this.appearanceBloc});

  final AuthBloc authBloc;
  final AppearanceBloc appearanceBloc;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createAppRouter(widget.authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: widget.authBloc),
      BlocProvider.value(value: widget.appearanceBloc),
    ],
    child: BlocSelector<AppearanceBloc, AppearanceState, ThemePreference>(
      selector: (state) => state.theme,
      builder: (context, theme) => MaterialApp.router(
        title: 'LifeQuest',
        debugShowCheckedModeBanner: false,
        theme: LifeQuestTheme.light,
        darkTheme: LifeQuestTheme.dark,
        themeMode: switch (theme) {
          ThemePreference.light => ThemeMode.light,
          ThemePreference.dark => ThemeMode.dark,
          ThemePreference.system => ThemeMode.system,
        },
        routerConfig: _router,
      ),
    ),
  );
}
